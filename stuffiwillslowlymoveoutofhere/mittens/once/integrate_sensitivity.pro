FUNCTION dfdlogp, period, coef=coef
	return, coef.k_P*period^coef.beta*(1-exp(-(period/coef.P_0)^coef.gamma))
END

FUNCTION dfdlogr,  radius, coef=coef
	return, coef.k_R*radius^coef.alpha;*(radius lt 2.0)
END


FUNCTION interpolate_sensitivity, period, radius, sensitivity=sensitivity
	common mearth_tools
	x = interpol(findgen(n_elements(sensitivity.period.detection[*,0])), sensitivity.period.grid, period)
	y = interpol(findgen(n_elements(sensitivity.period.detection[0,*])), sensitivity.radii, radius)
	return, interpolate(sensitivity.period.detection, x, y)
END

FUNCTION integrate_sensitivity, radius_range=radius_range, coef=coef, plot=plot, period_range=period_range, n_det=n_det, filename_for_sensitivity=filename_for_sensitivity, sensitivity=sensitivity

  ;	if ~keyword_set(sensitivity) then f = file_search(filename_for_sensitivity)
	common mearth_tools
	n = 100
	cleanplot, /silent
;	if ~keyword_set(sensitivity) then		restore, f

		
		n_radii = 100
		n_periods = 1000
		if keyword_set(radius_range) then begin
			min_radius = float(min(radius_range))
			max_radius = float(max(radius_range))
		endif else begin
			min_radius = min(sensitivity.radii)
			max_radius = 4.
		endelse
		dr = (max_radius- min_radius)/(n_radii-1)
		radius_grid = ones(n_periods)#(min_radius + findgen(n_radii)*dr)
		dlogr_grid = dr/radius_grid*alog10(exp(1))
		radius_axis = (min_radius + findgen(n_radii)*dr)

		if keyword_set(period_range) then begin
			min_period = float(min(period_range))
			max_period = float(max(period_range))
		endif else begin
			min_period = 0.5
			max_period = 10.0
		endelse

		dp = (max_period- min_period)/(n_periods-1)
		period_grid = (min_period + findgen(n_periods)*dp)#ones(n_radii)
		dlogp_grid = dp/period_grid*alog10(exp(1))
		period_axis =(min_period + findgen(n_periods)*dp)
	
; 		contour, period_grid, period_axis, radius_axis, /fill, nlevels=100, xs=1, ys=1
; 		smultiplot
; 		contour, radius_grid, period_axis, radius_axis, nlevels=100, /fill, xs=1, ys=1
		if not keyword_set(coef) then coef = {k_R:1.0, alpha:-1.92, k_P:0.064, beta:0.27, P_0:7.0, gamma:2.6}
;		coef = {k_R:1.0, alpha:-1.92, k_P:0.1, beta:0.27, P_0:1.0, gamma:2.6, k_tot:1.0}
	;	coef = {k_R:1.0, alpha:-1.92, k_P:0.002, beta:0.79, P_0:2.2, gamma:4.0, k_tot:1.0}
		coef.k_R = 1.0/((max_radius^coef.alpha - min_radius^coef.alpha)/coef.alpha)/alog10(exp(1))

		s = interpolate_sensitivity(period_grid, radius_grid, sensitivity=sensitivity)
	

	input_occ_rate = total(dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid)
	integral =  total(dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid*s)/input_occ_rate




if keyword_set(plot) then begin
		set_plot, 'ps'
		filename=stregex(/ex, filename_for_sensitivity, '[^.]+') + '_Rbetween'+string(format='(F04.1)', min_radius) + 'and'+ string(format='(F04.1)', max_radius)+'Pbelow'+string(format='(I02)', max_period)+  'days_withcutoffat'+string(format='(F3.1)', coef.p_0)+'days_contours.eps'
		device, filename=filename, /color, /encap, xsize=10, ysize=6, /inches
		!p.charsize=1.2
		!p.charthick=3
		smultiplot, /init, [3,3], ygap=0.02, xgap =0.05, rowh=[1,.2,1], colw=[1, 1, .4]


	smultiplot, /dox, /doy
	loadct, 47, file='~/zkb_colors.tbl'

		contour, (s), period_axis, radius_axis, nlevels=100, /fill, xs=1, ys=1, title=goodtex('MEarth sensitivity'), ytitle='Planet Radius !C(Earth radii)'
	loadct, 0
	plot, /noerase, period_axis, radius_axis, xs=1, ys=1,  xtitle='Planet Period (days)', ytitle='Planet Radius !C(Earth radii)', /nodata, xthick=3, ythick=3;title=goodtex('d^2f/dlogPdlogR'),

			smultiplot, /dox, /doy
	loadct, file='~/zkb_colors.tbl', 43
	contour, (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid), period_axis, radius_axis, nlevels=100, /fill, xs=1, ys=1,  xtitle='Planet Period (days)', ytitle='Planet Radius !C(Earth radii)';, /xlog, /ylog, title=goodtex('d^2f/dlogPdlogR'),
	loadct, 0
	plot, /noerase, period_axis, radius_axis, xs=1, ys=1,  xtitle='Planet Period (days)', ytitle='Planet Radius !C(Earth radii)', /nodata, xthick=3, ythick=3;title=goodtex('d^2f/dlogPdlogR'),

		smultiplot
		plot, [0], xs=4, ys=4, /nodata, xr=[0,1], yr=[0,1]
		tags = tag_names(coef)
		str = strcompress(n_elements(cloud)) + ' stars used!C!C'
		for q =0, n_tags(coef)-1 do str += tags[q] + ' = ' + strcompress(/remo, coef.(q)) + '!C'
		str += '!C!C!C!C'
		str += "(Kepler's) !Coccurence rate !Cin this box is !C    "+ strcompress( total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid)))+ ' !C'
		xyouts, /data, -1, 0.9,str, charsize=.7


		smultiplot
smultiplot
smultiplot

smultiplot, /dox, /doy
	loadct, 0
	plot, /noerase, period_axis, radius_axis, xs=1, ys=1,  xtitle='Planet Period (days)', ytitle='Planet Radius !C(Earth radii)', /nodata, xthick=3, ythick=3, color=0;title=goodtex('d^2f/dlogPdlogR'),
	loadct, 65, file='~/zkb_colors.tbl'
	z =  (s*dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid)
	contour,z, period_axis, radius_axis,levels=findgen(100)/100*max(z)*2, /fill, xs=1, ys=1, ytitle='Planet Radius !C(Earth radii)', xtitle='Planet Period (days)', /over;, title=goodtex('sensitivity x d^2f/dlogPdlogR')
	loadct, 0
	plot, /noerase, period_axis, radius_axis, xs=1, ys=1,  xtitle='Planet Period (days)', ytitle='Planet Radius !C(Earth radii)', /nodata, xthick=3, ythick=3;title=goodtex('d^2f/dlogPdlogR'),

		smultiplot
		plot, [0], xs=4, ys=4, /nodata
		str = ''
		str += 'if occurrence rate were 1, !CMEarth would expect !C      '+  string(integral, format='(F6.3)')+ ' !C'+'!C!C' 

		if not keyword_set(n_det) then n_det = 0
		str+= strcompress(n_det) + ' planets found, so... !C!C'
		 str +=  say_occurrence_rate( integral, n_det)
		al_legend,str, box=0, charsize=1.3

	;print, say_occurrence_rate( integral, n_det)



; 		legend, "MEarth's 3 sigma upper limit !C on the occurence rate is!C   " + strcompress(3/total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid*s))*total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid))) , box=0, charsize=.7
; 		print_struct, coef
;	print, 'expected number of detections, based on Kepler: ', total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid*s))
;	print, 'P < ', max_period, '; ', min_radius, ' < R < ', max_radius, ': (3 sigma confidence)' 
;	print,  3/total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid*s))*total( (dfdlogp(period_grid, coef=coef)*dfdlogr(radius_grid, coef=coef)*dlogp_grid*dlogr_grid))



	device, /close
	epstopdf, filename
endif
return, integral
END