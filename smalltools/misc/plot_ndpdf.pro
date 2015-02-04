PRO plot_ndpdf, clouds, eps=eps, dye=dye, res=res, tags=tags, symsize=symsize, psym=psym, flagged=flagged, charsize=charsize, log=log, fit=fit, fried_egg=fried_egg, fill=fill,  multiple=multiple, names = names, label=label, color_tables=color_tables

	!x.margin = [5,25]
	!y.margin = [5,15];10 and 3 for the X axis, and 4 and 2 for the Y

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
	;		
	;		example:
	;			a = randomn(seed, 100000) & b = randomn(seed, 100000) + a^2 & c = randomn(seed, 100000) & struct = {a:a, b:b, c:c} & plot_nd, struct, /fried, res=50
	;loadct, 39
	n_sigma = 6.0
	if keyword_set(multiple) then begin
		n_clouds = n_tags(clouds)
		if not keyword_set(cloud_names) then cloud_names = tag_names(clouds)
		if not keyword_set(cloud_colors) then cloud_colors = 0*indgen(n_clouds)*254.0/(n_clouds-1)
		c = clouds.(0)
	if not keyword_set(color_tables) then color_tables = [42, 60, 54]


	endif else c = clouds
	loadct, 0, /silent

	erase
	if not keyword_set(charsize) then charsize=0.7
	!p.charthick=2
	!p.charsize=charsize
	if not keyword_set(symsize) then symsize=0.5
	if not keyword_set(psym) then psym=1
	if keyword_set(dye) then scaled_dye = (dye - min(dye))*255.0/(max((dye - min(dye)))>0.0000001) else scaled_dye=!p.color
	if not keyword_set(res) then res = 20
	if not keyword_set(names) then names = tag_names(c)
	if not keyword_set(tags) then tags=indgen(n_elements(names))
	rms = fltarr(n_elements(tags))
	for i=0, n_elements(tags)-1 do rms[i] = stddev(c.(tags[i]))
	tags = tags[where(rms gt 0)]
	names = names[where(rms gt 0)]
	if total(rms gt 0) then return

	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=eps, /inches, xsize=6, ysize=6, /encapsulated, /color, /cmyk
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
	multiplot, /init, [d,d]
	theta = findgen(11)/10*2*!pi
;	s = sort(c.p)
	if not keyword_set(symsize) then symsize=1.0
	usersym, sin(theta)/3*symsize, cos(theta)/3*symsize, /fill 
	for i=0, d-1 do begin
		if i lt d then begin
				yr = median(c.(tags[i])) + [-1, 1]*n_sigma*mad(c.(tags[i]))
			;	yr = [min(c.(tags[i])), max(c.(tags[i]))]
				if keyword_set(multiple) then for k=1, n_clouds-1 do yr = [min([yr[0], median(clouds.(k).(tags[i])) - n_sigma*mad(/nan, clouds.(k).(tags[i]))]), max([yr[1], median( clouds.(k).(tags[i])) + n_sigma*mad(/nan, clouds.(k).(tags[i]))])]
		endif
		for j=0, d-1 do begin

			if i eq d-1 and j ge 0 then xtitle=names[j] else xtitle=' '
			if j lt 0 or i eq d then begin
				multiplot & plot, [0], /nodata, xticks=1, yticks=1, yticklayout=1, xticklayout=1, xtickname=[' ',' '], ytickname=[' ',' '], xs=0, ys=0
			endif else begin
				xr = median(c.(tags[j])) + [-1, 1]*n_sigma*mad(c.(tags[j]));)[min(c.(tags[j])), max(c.(tags[j]))]
				if keyword_set(multiple) then for k=1, n_clouds-1 do xr = [min([xr[0], median(clouds.(k).(tags[j])) - n_sigma*mad(/nan, clouds.(k).(tags[j]))]), max([xr[1], median( clouds.(k).(tags[j])) + n_sigma*mad(/nan, clouds.(k).(tags[j]))])]
;						if strmatch(names[j], goodtex( '(u_1+u_2)')+'*') eq 1 then begin
	;			print, 'using ad hoc xrange', names[j]
;				xr = [0.2001, 1.0]

;			endif else begin
			;	xr = [min(c.(tags[j])), max(c.(tags[j]))];
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
					loadct, 0, /silent
					plothist, /nan, [xr[0],c.(tags[i])],   xstyle=5, ystyle=5, bin=(xr[0] - xr[1])/res,  xrange=xr, thick=3, xlog=log, ytickn=[' ',' ',' ',' ',' ',' ',' ',' ',' ',' '], xtickname=xtickname, /noplot, xval, yval
					hist_yr = [0,max(yval)*3.0/n_elements(c.(tags[i]))]
					plot, [0], xrange=xr, yrange=hist_yr, xs=5, ys=5, psym=10
					axis, xaxis=0, xtickn=[' ',' ',' ',' ',' ',' ',' ',' ',' ',' ']
				;	axis, yaxis=0, ytickn=[' ',' ',' ',' ',' ',' ',' ',' ',' ',' ']
				;	plothist, /nan, [xr[0],c.(tags[i])],   xstyle=5,  ystyle=5, bin=(xr[0] - xr[1])/res,  xrange=xr, thick=3, xlog=log,  charsize=1.5*!p.charsize, charthick=3, ytickname=replicate('  ',20), xtickname=replicate('  ',20), xtitle=xtitle, yrange=[0,max(yval)*2.0/n_elements(c.(tags[i]))]; title=names[i],
				;	axis,  /xaxis
				;	axis, /ystyle, /yaxis
	; HACK TO HANDLE FLAT ARRAYS! DEAL WITH!
					xpos = mean(xr);max(xval)
					ypos = hist_yr[1]*0.5;max(yval)
					xyouts, xpos, ypos, orient=45, names[i], charsize=1
					spaces = ''
					if keyword_set(multiple) then for k=0, n_clouds-1 do begin
						loadct, file='~/zkb_colors.tbl', color_tables[k], /silent
						plothist, /nan, /overplot, bin=(xr[0] - xr[1])/res,  thick=3, color=cloud_colors[k],  [xr[0], clouds.(k).(tags[i])], xstyle=5, /noplot, xval, yval
						oplot, thick=3, color=cloud_colors[k], xval, yval*1.0/n_elements(clouds.(k).(tags[i])), psym=10
						spaces += '!C!C     '
						xyouts, xpos, ypos, orient=45, spaces+stregex(goodtex(latex_confidence(clouds.(k).(tags[i]), /auto)), '[^$]+', /extract), charsize=.9, color=cloud_colors[k], charthick=1

						loadct, 0, /silent
					endfor


				endif else begin
					if i lt j then begin
						multiplot & plot, [0], /nodata, xticks=1, yticks=1, yticklayout=1, xticklayout=1, xtickname=[' ',' '], ytickname=[' ',' '], xs=0, ys=0
						if i eq 0 and j eq d-1 then begin
							if keyword_set(label) then legend, box=0, [label, strcompress(n_elements(c.(0))) + ' points'], charsize=3*!p.charsize, /right, /top
						endif
						if j eq d-1 and i eq 0 and keyword_set(multiple) then for k=0, n_clouds-1 do begin
							loadct, file='~/zkb_colors.tbl', color_tables[k], /silent
							xyouts, 0.9, 0.9-k/20.0, cloud_names[k], color=cloud_colors[k], charsize=2, /norm, align=1.0
						endfor
						loadct, 0, /silent
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
					plot, c.(tags[j]), c.(tags[i]), xstyle=5, xrange=xr, yrange=yr, ystyle=5,/nodata, ylog=log, xlog=log;, xtickname=xtickname, ytickname=ytickname;,  xtitle=xtitle, ytitle=ytitle

					if keyword_set(xtitle) then plot,  c.(tags[j]), c.(tags[i]), xstyle=5, xrange=xr, yrange=yr, ystyle=5,/nodata, ylog=log, xlog=log, xtitle=xtitle, charsize=1.5*!p.charsize, xtickname=replicate('  ',20), ytickname=replicate('  ',20),charthick=3
					if keyword_set(ytitle) then plot, c.(tags[j]), c.(tags[i]),  xstyle=5, xrange=xr, yrange=yr, ystyle=5,/nodata, ylog=log, xlog=log , ytitle=ytitle, charsize=1.5*!p.charsize, ytickname=replicate('  ',20), xtickname=replicate('  ',20),charthick=3

				;		oplot, [-1000,1000], [0,0], linestyle=5
				;		oplot, [0,0], [-1000,1000], linestyle=5

						if keyword_set(multiple)  then begin
							for k=0, n_clouds-1 do begin
								loadct, file='~/zkb_colors.tbl', color_tables[k], /silent
								x_interval = confidence_interval(clouds.(k).(tags[j]))
								vline, x_interval[1], linestyle=0,color=210
								vline, x_interval[[0,2]], linestyle=1,color=210
								y_interval = confidence_interval(clouds.(k).(tags[i]))
								hline, y_interval[1], linestyle=0,color=210
								hline, y_interval[[0,2]], linestyle=1,color=210

								loadct, 0, /silent
							endfor
						endif
	
						if keyword_set(fried_egg) then begin
							if keyword_set(multiple) then for k=0, n_clouds-1 do begin
								loadct, file='~/zkb_colors.tbl', color_tables[k], /silent
								fried_egg, fill=fill,   clouds.(k).(tags[j]), clouds.(k).(tags[i]), /overplot, res=res, color=cloud_colors[k], xrange=xr, yrange=yr 
							endfor else fried_egg, fill=fill,  c.(tags[j]), c.(tags[i]), /overplot, res=res , xrange=xr, yrange=yr 
							loadct, 0, /silent
						endif else begin
							if keyword_set(multiple) then for k=0, n_clouds-1 do begin
								loadct, file='~/zkb_colors.tbl', color_tables[k], /silent
								plots, clouds.(k).(tags[j]), clouds.(k).(tags[i]), psym=psym, symsize=symsize, color=cloud_colors[k], noclip=0 
							endfor else plots, c.(tags[j]), c.(tags[i]), psym=psym, color=scaled_dye, symsize=symsize, noclip=0
							loadct, 0, /silent
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
