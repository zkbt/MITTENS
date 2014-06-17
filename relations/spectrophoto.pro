PRO runthisinidl7
		; SQL query only seems to work in IDL7.0
		; (run after saying)
		; setenv IDL_DIR /opt/idl/idl_7.0
		; setenv IDL_DLM_PATH /data/mearth1/db/idl
		; setenv PGSERVICE mearth
	
	query = 	"SELECT numspectype as numerical_spectype, " + $
			"	plx as parallax, " + $
			"	e_plx as e_parallax, " + $
			"	vmag, " + $
			"	jmag, " + $
			"	hmag, " + $
			"	kmag, " + $
			"	e_vmag, " + $
			"	e_jmag, " + $
			"	e_hmag, " + $
			"	e_kmag, " + $
			"	mass, " + $
			"	radius " + $
			"FROM nc_adopt_best " + $
			"WHERE numspectype >= 0;"
	sql = pgsql_query(query, /verb) 
	save, sql, filename='sql.idl'

END

PRO spectrophoto, just_display=just_display
	if ~keyword_set(just_display) then runthisinidl7
	restore, 'sql.idl'
	for i=0, n_tags(sql)-1 do begin
		j = where(sql.(i) gt 0 and sql.(i) lt 10.0^(-20), n_null)
		if n_null gt 0 then sql[j].(i) = 0.0/0.0
	endfor

	i = where(sql.vmag gt 1 and sql.parallax gt 0.000001 and sql.e_parallax gt 0 and sql.numerical_spectype lt 10)

	sql = sql[i]
	parallax = sql.parallax
	e_parallax = sql.e_parallax
	distance = 1.0/parallax
	e_distance = e_parallax/parallax^2
	dm = 5.0*alog10(1.0/parallax) - 5.0
	e_dm = 5.0/alog(10)*e_parallax/parallax

	mass = sql.mass
	radius = sql.radius

	kapparent = sql.kmag
	kabsolute = kapparent - dm
	
	japparent = sql.jmag
	jabsolute = japparent - dm

	vapparent = sql.vmag
	vabsolute = vapparent - dm


	mass = delfosse(kabsolute)
	e_2mass = 0.02
	e_v = 0.5
	e_kabsolute = sqrt(e_dm^2 + sql.e_kmag^2)
	e_jabsolute = sqrt(e_dm^2 + sql.e_jmag^2)
	e_vabsolute = sqrt(e_dm^2 + sql.e_vmag^2)
	; major kludge! for mass error estimate
	e_mass = mass*0.4*alog(10)*e_kabsolute
	type = sql.numerical_spectype
	cleanplot

	!p.multi=[0,1,1]
	@psym_circle
	usersym, cos(theta), sin(theta)
	dm_color = (1.0/e_kabsolute^2 < 1)*254.
	sorted = reverse(sort(dm_color))
	xplot
	loadct, 0
	plot, type[sorted], kabsolute[sorted], /nodata, xs=3, ys=3
;	ploterror, type, kabsolute, e_kabsolute, psym=8, yr = range(jabsolute), ys=3, xs=3, /nodata
	plots, type[sorted] + randomn(seed, n_elements(type))*0.5, kabsolute[sorted], psym=8, color =dm_color
; 	ploterror, type + randomn(seed, n_elements(type))*0.5, kabsolute, e_kabsolute, psym=8, yr = range(kabsolute), ys=3, xs=3
; tio1:sql.tio1, tio2:sql.tio2, tio3:sql.tio3, tio4:sql.tio4, tio5:sql.tio5, cah1:sql.cah1, cah3:sql.cah3,
	independent_variables = {spectral_type:type, v_minus_k:vapparent-kapparent}
	dependent_variables = {v_absolute:vabsolute, k_absolute:kabsolute}
	uncertainty_variables = {v_absolute:e_vabsolute, k_absolute:e_kabsolute}
	x_names = tag_names(independent_variables)
	y_names = tag_names(dependent_variables)
	
	if ~keyword_set(just_display) then begin
		for i=0, n_elements(x_names)-1 do begin
			for j=0, n_elements(y_names)-1 do begin
				if x_names[i] eq y_names[j] then continue

				filename = x_names[i] + '_vs_' + y_names[j] + '_fit.idl'
				;if file_test(filename) eq 1 then continue
				fit = hogg_polyfit(independent_variables.(i), dependent_variables.(j), uncertainty_variables.(j), order=2, /intrinsic, /plot, xtitle=x_names[i], ytitle=y_names[j], n_chain=500000)
				save, fit, filename=filename
				print, '   saved fit to ' + filename
			endfor
		endfor
	endif
	order = 2
;	fit = hogg_polyfit(type, vapparent-kapparent, e_2mass*ones(n_elements(vapparent)), order=2, /intrinsic, /plot)
;	fit = hogg_polyfit(type, kabsolute, e_kabsolute, order=3, /intrinsic, /plot)
	set_plot, 'ps'
	device, filename='spectro_relations.eps', /encap, xsize=20, ysize=14, /inches, /color
	smultiplot, /init, [n_elements(x_names), n_elements(y_names)], /rowma, xgap =0.001, ygap=0.005
	for i=0, n_elements(x_names)-1 do begin
		for j=0, n_elements(y_names)-1 do begin
			filename = x_names[i] + '_vs_' + y_names[j] + '_fit.idl'
			if file_test(filename) eq 0 then continue
			restore, filename
			smultiplot

			xtitle=x_names[i]
			ytitle=y_names[j]
			if x_names[i] eq y_names[j] then continue
			strreplace, xtitle, '_', ' '
			strreplace, ytitle, '_', ' '
			strreplace, xtitle, '_', ' '
			strreplace, ytitle, '_', ' '
			input_x = independent_variables.(i)
			input_y = dependent_variables.(j)
			uncertainty_y = uncertainty_variables.(j)
			i_ok = where(finite(input_x) and finite(input_y) and finite(uncertainty_y) and uncertainty_y lt 5*1.48*mad(uncertainty_y), n_finite)
			if n_finite gt 0 then begin
				x = input_x[i_ok]
				y = input_y[i_ok]
				uncertainty_y = uncertainty_y[i_ok]
			endif 			
			if strmatch(x_names[i], '*TYPE*') ne 0 then off = (randomu(seed, n_elements(x)) - 0.5)*0.2 else off = fltarr(n_elements(x))
			if i eq 0 then yt = ytitle else yt = ''
			if j eq n_elements(y_names)-1 then xt = xtitle else xt = ''

			plot, x, y, /nodata, xs=3, ys=3, xtitle=xt, ytitle=yt, xr=range(input_x), yr=range(input_y)
			n_grid = 50
			x_axis = findgen(n_grid)/(n_grid-1)*(max(input_x) - min(input_x)) + min(input_x)
			for q=0, 10 do begin
				which = randomu(seed)*n_elements(fit.(0))
				model = fltarr(n_grid)
				for k=0, order do model += fit[which].(k)*x_axis^k		
				oplot, x_axis, model, thick=1, color=150	
			endfor	
			oploterr, x+off, y, uncertainty_y, 8

			statement = goodtex(ytitle + ' = ('+stregex(latex_confidence(fit.poly0, /auto), '[^$]+', /ext) + ') + ('+stregex(latex_confidence(fit.poly1, /auto), '[^$]+', /ext) +' \times '+xtitle+') + ('+stregex(latex_confidence(fit.poly2, /auto), '[^$]+', /ext) +' \times '+xtitle+'^2)'+'!C!Cwith ' + stregex(latex_confidence(fit.outlier_probability*100, /auto), '[^$]+', /ext) + '% outlier fraction'+ '!C!Cand ' + stregex(latex_confidence(fit.intrinsic_scatter, /auto), '[^$]+', /ext) + ' intrinsic scatter')
			if strmatch(ytitle, '*MINUS*') eq 0 then statement += goodtex( '!C!Cimplying distances to ' + string(median(fit.intrinsic_scatter*alog(10)/5)*100,format = '(I2)')+ '%')
			right = (model[n_grid-1] lt model[0])
			al_legend, right=right, left=~right, /top, box=0, statement, charsize=0.5
			al_legend, /bottom, right=~right, left=right, box=0, rw(n_elements(x)) + ' stars'
		;	if question('hmmm?', /int) then stop
		endfor
	endfor
	smultiplot, /def
	device, /close
	epstopdf, 'spectro_relations.eps'
END