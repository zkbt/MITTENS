PRO marpleplot_phasedemo, eps=eps
; demonstrate how to phase up multiple MarPLE's, in one succinct plot
	common mearth_tools
	common this_star
	cleanplot
	restore, star_dir + 'box_pdf.idl'
	restore, star_dir + 'cleaned_lc.idl'
	lc = cleaned_lc[where(cleaned_lc.okay)]
	in_an_intransit_box = in_an_intransit_box[where(cleaned_lc.okay)]
	; plot cleaned light curve

zoomfactor = 3

	; plot boxes \pm errors (zoomed and unzoomed)
	filename = 'marpleplot_phasedemo.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=3, /inches, /color, decomposed=0
	endif
	!p.charsize=1.0
	!x.margin=[11,2]
	scale = 1.5*(candidate.depth+candidate.depth_uncertainty) > 5*1.48*mad(cleaned_lc.flux)
	scale = scale < 0.05
	yr = scale*[1,-1]




	smultiplot, /init, [2,2], xgap=0.008, colwid=[1, .5], ygap=0.014

	if not keyword_set(p_min) then p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
	pad = long((max(lc.hjd) - min(lc.hjd))/p_min)+1
	; define the night for each data point (an integer, should turn over at midday)
 	nights = round(boxes.hjd -mearth_timezone())

	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	k_best =  value_locate(boxes[0].duration-duration_bin/2, candidate.duration)  
	i_interesting = where(boxes.n[k_best] gt 0, n_interesting)
	i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidate, n_it, /boxes)]
	phased_time = (boxes.hjd - mean(candidate.hjd0))/mean(candidate.period) + pad + 0.5
	orbit_number = long(phased_time)
	phased_time = (phased_time - orbit_number - 0.5)*mean(candidate.period)
					
	i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
	h = histogram(nights[i_intransit], reverse_indices=ri)
	ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
	uniq_intransit =(ri[ri_firsts])

	symsize = 0.3
	theta = findgen(17)/16*2*!pi
	usersym, cos(theta), sin(theta)
	xvert = [-candidate.period/2, -candidate.duration/2, -candidate.duration/2, candidate.duration/2, candidate.duration/2, candidate.period/2]
	big =1.2

	smultiplot
	loadct, 0, /silent
	plot, phased_time[i_interesting], boxes[i_interesting].depth[k_best], psym=8, yrange=yr, ytitle=goodtex('D\pm\sigma_{MarPLE}!C'), /nodata, xr=[-candidate.period/2, candidate.period/2], xmargin=[30,5], xs=3

	loadct, file='~/zkb_colors.tbl', 58
	polyfill, candidate.duration/2*[-1,1,1,-1], [(candidate.depth + candidate.depth_uncertainty), (candidate.depth + candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty)], color=200
	oplot, xvert, [0,0,1,1,0,0]*(candidate.depth + candidate.depth_uncertainty), color=100, thick=3
	oplot, xvert, [0,0,1,1,0,0]*(candidate.depth - candidate.depth_uncertainty), color=100, thick=3
;	vline, -candidate.duration/2, linestyle=2, color=200
;	vline, candidate.duration/2, linestyle=2, color=200
	loadct, 0
	oploterror, phased_time[i_interesting], boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best], color=125, errcolor=150, psym=8, symsize=symsize
	usersym, cos(theta)*big, sin(theta)*big, /fill
	oploterror, phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k_best], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k_best],  psym=8, symsize=symsize
			
	smultiplot
	units = 24*60	
	loadct, 0, /silent
	plot, units*phased_time[i_interesting], boxes[i_interesting].depth[k_best], psym=8, yrange=yr, /nodata, xr=[-candidate.duration/2, candidate.duration/2]*zoomfactor*units, xmargin=[30,5], xs=3
	usersym, cos(theta), sin(theta)

	loadct, file='~/zkb_colors.tbl', 58
	polyfill, units*candidate.duration/2*[-1,1,1,-1], [(candidate.depth + candidate.depth_uncertainty), (candidate.depth + candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty)], color=200
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth + candidate.depth_uncertainty), color=100, thick=3
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth - candidate.depth_uncertainty), color=100, thick=3
;	vline, -candidate.duration/2*units, linestyle=2, color=200
;	vline, candidate.duration/2*units, linestyle=2, color=200
	loadct, 0
	oploterror, units*phased_time[i_interesting], boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best], color=125, errcolor=150, psym=8, symsize=symsize
	usersym, cos(theta)*big, sin(theta)*big, /fill
	oploterror, units*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k_best], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k_best],  psym=8, symsize=symsize


	phased_lctime = (lc.hjd - mean(candidate.hjd0))/mean(candidate.period) + pad + 0.5
	orbit_lcnumber = long(phased_lctime)
	phased_lctime = (phased_lctime - orbit_lcnumber - 0.5)*mean(candidate.period)
	i_lcintransit = where(in_an_intransit_box)
	smultiplot
	usersym, cos(theta), sin(theta)
	units = 1
	loadct, 0, /silent
	plot, phased_lctime, lc.flux,  xr=[-candidate.period/2, candidate.period/2], xs=3, psym=8, yrange=yr, xtitle='Phased Time (days)',/nodata, xmargin=[30,5], ytitle='MAP Cleaned!CPhotometry (mag.)'
	loadct, file='~/zkb_colors.tbl', 58
	polyfill, units*candidate.duration/2*[-1,1,1,-1], [(candidate.depth + candidate.depth_uncertainty), (candidate.depth + candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty)], color=200
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth + candidate.depth_uncertainty), color=100, thick=3
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth - candidate.depth_uncertainty), color=100, thick=3
;	vline, -candidate.duration/2*units, linestyle=2, color=200
;	vline, candidate.duration/2*units, linestyle=2, color=200
	loadct, 0
	oplot, phased_lctime, lc.flux, color=150,psym=8, symsize=symsize
	usersym, cos(theta)*big, sin(theta)*big, /fill
	oplot, phased_lctime[i_lcintransit], lc[i_lcintransit].flux, psym=8, symsize=symsize


	smultiplot
	units = 24*60
	loadct, 0, /silent
	usersym, cos(theta), sin(theta)

	plot, 24*60*phased_lctime, lc.flux, xr=[-candidate.duration/2, candidate.duration/2]*zoomfactor*units, psym=8, yrange=yr, xtitle='Phased Time (minutes)',/nodata, xmargin=[30,5], xs=3
	loadct, file='~/zkb_colors.tbl', 58
	polyfill, units*candidate.duration/2*[-1,1,1,-1], [(candidate.depth + candidate.depth_uncertainty), (candidate.depth + candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty)], color=200
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth + candidate.depth_uncertainty), color=100, thick=3
	oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth - candidate.depth_uncertainty), color=100, thick=3
;	vline, -candidate.duration/2*units, linestyle=2, color=200
;	vline, candidate.duration/2*units, linestyle=2, color=200

	loadct, 0
	oplot, 24*60*phased_lctime, lc.flux, color=150,  psym=8, symsize=symsize
	usersym, cos(theta)*big, sin(theta)*big, /fill

	oplot, units*phased_lctime[i_lcintransit], lc[i_lcintransit].flux, psym=8, symsize=symsize



	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
stop
END