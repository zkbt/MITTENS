PRO plot_nd, clouds, eps=eps, dye=dye, res=res, tags=tags, symsize=symsize, psym=psym, flagged=flagged, charsize=charsize, log=log, fit=fit, fried_egg=fried_egg, fill=fill,  multiple=multiple, names = names, label=label, xgap=xgap, ygap=ygap

	!x.margin = [10,3]
	!y.margin = [6,4];10 and 3 for the X axis, and 4 and 2 for the Y
	;  plot_nd.pro
	;  by zach
	;
	;	where "c" is a structure containing "n" tags (either as c[*].tag or c.tag[*]), plot_nd will produce
	;	a matrix of plots showing every possible combination of one vs. the other. 
	;		eps = "filename.eps" into which an EPS will be saved
	;		dye = an array (same size as c[*].tag) by which values point will be dyed in rainbow colors
	;		res = number of bins in 1D histogram
	;		psym = psym
	;		symsize = symsize
	;		/normal_ticks = don't use assymmetric confidence intervals as labels
	;		/fried_egg = use contours instead of plotting each point

	;			a = randomn(seed, 100000) & b = randomn(seed, 100000) + a^2 & c = randomn(seed, 100000) & struct = {a:a, b:b, c:c} & plot_nd, struct, /fried, res=50, /fill


	;loadct, 39
	n_sigma = 4.0
	if keyword_set(multiple) then begin
		n_clouds = n_tags(clouds)
		if not keyword_set(cloud_names) then cloud_names = tag_names(clouds)
		if not keyword_set(cloud_colors) then cloud_colors = indgen(n_clouds)*254.0/(n_clouds-1)
		c = clouds.(0)
	endif else c = clouds

	erase
	if not keyword_set(charsize) then charsize=0.7
	!p.charthick=2
	!p.charsize=charsize
	if not keyword_set(symsize) then symsize=0.5
	if not keyword_set(psym) then psym=1
	if keyword_set(dye) then scaled_dye = (dye - min(dye))*254.0/(max((dye - min(dye)))>0.0000001) else scaled_dye=!p.color
	if not keyword_set(res) then res = 20
	if not keyword_set(names) then names = tag_names(c)
	if not keyword_set(tags) then tags=indgen(n_elements(names))
	rms = fltarr(n_elements(tags))
	type = intarr(n_elements(tags))
	for i=0, n_elements(tags)-1 do begin
		type[i] = size(/type, c.(tags[i]))
		if type[i] ne 7 then rms[i] = stddev(c.(tags[i]), /nan)
	endfor
	i_okay = where(rms gt 0 and type ne 7, n_okay)
	if n_okay gt 0 then tags = tags[i_okay] else begin
		print, "!%_(!^* there aren't any interesting, plottable tags in the structure!"
		return
	endelse
	names = names[tags]

	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=eps, /inches, xsize=7.5, ysize=7.5, /encapsulated, /color
	endif

	d = n_elements(names)

	if keyword_set(fit) then begin
		to_fit = where(names eq fit, complement=not_to_fit, n_to_fit)
		print, ' FITTING A LINEAR FUNCTION FOR ', fit
		if n_to_fit eq 1 then begin
			N = n_elements(c.(tags[to_fit]))
			M = d - 1
			A = fltarr(N, M)
        		b = alog(c.(tags[to_fit]))
			for i=0, M -1 do A[*,i] = alog(c.(tags[i]))
			alpha = transpose(A)#A
			beta = transpose(A)#b
			inverted = invert(alpha, /double)
			coef = inverted#beta
			model = A#coef
			chi_sq = total((b-A#coef)^2)
			print, string(coef) + ' ' + names[not_to_fit] + ' + '
		endif
	endif else to_fit = -1
	multiplot, /init, [d,d], xgap=xgap, ygap=ygap
	theta = findgen(11)/10*2*!pi
;	s = sort(c.p)
	if not keyword_set(symsize) then symsize=1.0
	usersym, sin(theta)/3*symsize, cos(theta)/3*symsize, /fill 
	for i=0, d-1 do begin
		if i lt d then begin
				yr = [min(c.(tags[i])), max(c.(tags[i]))]
			;	if keyword_set(multiple) then for k=1, n_clouds-1 do yr = [min([yr[0], mean(/nan, clouds.(k).(tags[i])) - n_sigma*mad(/nan, clouds.(k).(tags[i]))]), max([yr[1], mean(/nan, clouds.(k).(tags[i])) + n_sigma*mad(/nan, clouds.(k).(tags[i]))])]
		endif
		for j=0, d-1 do begin

			if i eq d-1 and j ge 0 then xtitle=names[j] else xtitle=' '
			if j lt 0 or i eq d then begin
				multiplot & plot, [0], /nodata, xticks=1, yticks=1, yticklayout=1, xticklayout=1, xtickname=[' ',' '], ytickname=[' ',' ']
			endif else begin
				;xr = mean(c.(tags[j])) + [-1, 1]*n_sigma*mad(c.(tags[j]));)[min(c.(tags[j])), max(c.(tags[j]))]
			;	if keyword_set(multiple) then for k=1, n_clouds-1 do xr = [min([xr[0], mean(/nan, clouds.(k).(tags[j])) - n_sigma*mad(/nan, clouds.(k).(tags[j]))]), max([xr[1], mean(/nan, clouds.(k).(tags[j])) + n_sigma*mad(/nan, clouds.(k).(tags[j]))])]
;						if strmatch(names[j], goodtex( '(u_1+u_2)')+'*') eq 1 then begin
	;			print, 'using ad hoc xrange', names[j]
;				xr = [0.2001, 1.0]

;			endif else begin
				xr = [min(c.(tags[j])), max(c.(tags[j]))];
;			endelse
;			if strmatch(names[i], goodtex( '(u_1+u_2)')+'*') eq 1 then begin
		;		print, 'using ad hoc xrange', names[i]
;				yr = [0.2001, 1.0]
;			endif 
				if i eq j then begin
				;	if i eq d-1 then xtitle=names[i] else xtitle=''
					multiplot
;							if strmatch(names[j], goodtex( '(u_1+u_2)')+'*') eq 1 and i eq d -1 then begin
							;	xtickname = [' ', '0.2', '0.4', '0.6', '0.8', '1.0']
;							endif 
					plothist, /nan, [xr[0],c.(tags[i])],   xstyle=1,  bin=(xr[0] - xr[1])/res,  xrange=xr, thick=3, xlog=log, ytickn=[' ',' ',' ',' ',' ',' ',' ',' ',' ',' '], xtickname=xtickname
					plothist, /nan, [xr[0],c.(tags[i])],   xstyle=1,  bin=(xr[0] - xr[1])/res,  xrange=xr, thick=3, xlog=log, title=names[i],  charsize=1.5*!p.charsize, charthick=2, ytickname=replicate('  ',20), xtickname=replicate('  ',20), xtitle=xtitle
				;	axis,  /xaxis
				;	axis, /ystyle, /yaxis
	; HACK TO HANDLE FLAT ARRAYS! DEAL WITH!
			;		if keyword_set(multiple) then for k=1, n_clouds-1 do plothist, /nan, /overplot, bin=(xr[0] - xr[1])/res,  thick=3, color=cloud_colors[k], [0, clouds.(k).(tags[i])], peak=1.0
				endif else begin
					if i lt j then begin
						multiplot & plot, [0], /nodata, xticks=1, yticks=1, yticklayout=1, xticklayout=1, xtickname=[' ',' '], ytickname=[' ',' ']
						if i eq 0 and j eq d-1 then begin
							if keyword_set(label) then legend, box=0, [label, strcompress(n_elements(c.(0))) + ' points'], charsize=3*!p.charsize, /right, /top
						endif
					;	if j eq d-1 and i eq 0 and keyword_set(multiple) then legend, box=0, cloud_names, color=cloud_colors, linestyle=fltarr(n_clouds), charsize=1, /right, /top

					endif else begin
						ytickv = confidence_interval(c.(tags[i]))
						yticks = n_elements(ytickv) -1
						if j eq 0 then begin
							ytitle=names[i] 
							ytickname=''
					;		if strmatch(names[i], goodtex( '(u_1+u_2)')+'*') eq 1 then ytickname = [' ', '0.2', '0.4', '0.6', '0.8', '1.0'] else ytickname=''
 						endif else begin
 							ytitle=''
							ytickname=replicate(' ',30)
						endelse
						if i eq d-1 then begin
							xtitle=names[j]
							xtickname = ''
;							if strmatch(names[j], goodtex( 'a/R_*')) eq 1 then begin
						;		print, 'using ad hoc xtitle!;
;								xtickname = [' ', '15.4', ' ', '15.0', ' ' , '14.6', ' '] 
;							endif
;							if strmatch(names[j], goodtex('R_p/R_*')) eq 1 then begin
						;		print, 'using ad hoc xtitle!;
;								xtickname = ['0.114', ' ', '0.116', ' ', '0.118' , ' '] 
;							endif
;							if strmatch(names[j], goodtex( '(u_1+u_2)')+'*') eq 1 then begin
						;		xtickname = [' ', '0.2', '0.4', '0.6', '0.8', '1.0']
;							endif
						endif else begin
							xtitle=''
						endelse
						multiplot 
					plot, c.(tags[j]), c.(tags[i]), xstyle=1, xrange=xr, yrange=yr, ystyle=1,/nodata, ylog=log, xlog=log;, xtickname=xtickname, ytickname=ytickname;,  xtitle=xtitle, ytitle=ytitle
					if keyword_set(xtitle) then plot,  c.(tags[j]), c.(tags[i]), xstyle=1, xrange=xr, yrange=yr, ystyle=1,/nodata, ylog=log, xlog=log, xtitle=xtitle, charsize=1.5*!p.charsize, xtickname=replicate('  ',20), ytickname=replicate('  ',20),charthick=2
					if keyword_set(ytitle) then plot, c.(tags[j]), c.(tags[i]),  xstyle=1, xrange=xr, yrange=yr, ystyle=1,/nodata, ylog=log, xlog=log , ytitle=ytitle, charsize=1.5*!p.charsize, ytickname=replicate('  ',20), xtickname=replicate('  ',20),charthick=2

				;		oplot, [-1000,1000], [0,0], linestyle=1
				;		oplot, [0,0], [-1000,1000], linestyle=1

						if keyword_set(fried_egg) then begin
							if keyword_set(multiple) then for k=0, n_clouds-1 do fried_egg, fill=fill,  clouds.(k).(tags[j]), clouds.(k).(tags[i]), /overplot, res=res, color=cloud_colors[k], xrange=xr, yrange=yr else fried_egg, fill=fill,  c.(tags[j]), c.(tags[i]), /overplot, res=res , xrange=xr, yrange=yr 
						endif else begin
							if keyword_set(multiple) then for k=0, n_clouds-1 do plots, clouds.(k).(tags[j]), clouds.(k).(tags[i]), psym=psym, symsize=symsize, color=cloud_colors[k], noclip=0 else plots, c.(tags[j]), c.(tags[i]), psym=psym, color=scaled_dye, symsize=symsize, noclip=0
						endelse
						if i eq to_fit then begin
							sorted_x = c.(tags[j])
							sorted_i = sort(sorted_x)
							sorted_x = sorted_x[sorted_i]
							sorted_y = exp(model[sorted_i])
							oplot, sorted_x, sorted_y, linestyle=0
						endif
					endelse
				endelse

			endelse
		endfor
	endfor
	multiplot, /default
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
	endif

END
