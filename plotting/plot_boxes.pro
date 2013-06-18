PRO plot_boxes, boxes, mark=mark, red_variance=red_variance, log=log, eps=eps, candidate=candidate, png=png, externalformatting=externalformatting, nobottom=nobottom, hold=hold, demo=demo, leg=leg
	common this_star
	common mearth_tools
	@filter_parameters
	if keyword_set(eps) then begin
		set_plot, 'ps'
		file_mkdir, star_dir() + 'plots/'
		filename=star_dir() + 'plots/' + 'boxes.eps'
		device, filename=filename, /encapsulated, /color, xsize=12, ysize=4, /inches
	endif
		if n_elements(candidate) gt 0 then begin
			i_intransitboxes = where_intransit(boxes, candidate, n_intransitboxes, buffer=-candidate.duration/4)
			p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
			pad = long((max(boxes.hjd) - min(boxes.hjd))/p_min)+1
			phased_time = (boxes.hjd - candidate.hjd0)/candidate.period + pad + 0.5
			orbit_number = long(phased_time)
			phased_time = (phased_time - orbit_number - 0.5)*candidate.period
 			boxes_nights = round(boxes.hjd -mearth_timezone())
			if n_intransitboxes gt 0 then begin
				i_intransitboxes = i_intransitboxes[sort(abs(phased_time[i_intransitboxes]))]
				h = histogram(boxes_nights[i_intransitboxes], reverse_indices=ri)
				ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
				uniq_intransit =(ri[ri_firsts])
				mark=i_intransitboxes[uniq_intransit]
			endif
		endif
		if ~keyword_set(externalformatting) then !p.charsize=1.5
		smultiplot, [1+n_elements(boxes[0].depth),1], /init, colw=[1.5,.1*ones(n_elements(boxes[0].depth))]
		smultiplot
		sn =  boxes.depth/boxes.depth_uncertainty
		i_interesting = where(boxes.n gt 0)
		if n_elements(red_variance) gt 0 then begin
			uncorrected_sn =  sn
			for i=0, n_elements(boxes[0].depth)-1 do begin
				uncorrected_sn[i,*] *= sqrt(1.0 + boxes[*].n[i]*red_variance[i])
			endfor
		endif else uncorrected_sn = sn
		if keyword_set(demo) then sn = uncorrected_sn
		if ~keyword_set(hold) then !y.range=reverse(range(sn[i_interesting]))
		loadct, 39, /silent
		if keyword_set(nobottom) then xtitle='' else xtitle = '                                                                 '+goodtex('Hypothetical Epochs of Lone Eclipses (in gridpoints, with gaps removed)                 [histograms of D/\sigma_{MarPLE} for different durations]')
		if keyword_set(nobottom) then !x.tickname = replicate(' ', 30)
		plot, boxes.depth[0]/boxes.depth_uncertainty[0], /nodata, ytitle=goodtex('D/\sigma_{MarPLE}')+'!C!D(box signal-to-noise)', xs=3, xtitle=xtitle, ys=3

		oplot_days, boxes.hjd, -!y.range[1], /top
		if keyword_set(mark) then begin
			duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
			i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration) > 0
			theta = findgen(21)/20*2*!pi
			usersym, cos(theta), sin(theta)
			plots, mark, boxes[mark].depth[i_duration]/boxes[mark].depth_uncertainty[i_duration]/(boxes[mark].n[i_duration] gt 0), color=(i_duration+1)*254.0/n_elements(boxes[0].depth)+0.01, psym=8, symsize=2
		endif
		n_depths = n_elements(boxes[0].depth)	;
		if n_elements(red_variance) gt 0 and ~keyword_set(demo) then begin
			for j=0, n_elements(boxes[0].depth)-1 do begin
				i = j;(n_depths-1-j) 
				oplot, uncorrected_sn[i,*]/(boxes.n[i] gt 0), color=(i+1)*254.0/n_elements(boxes[0].depth)+0.01, linestyle=1, thick=1
			endfor	
	endif
		for j=0, n_elements(boxes[0].depth)-1 do begin
			i =j; (n_depths-1-j) 
			oplot, sn[i,*]/(boxes.n[i] gt 0), color=(i+1)*254.0/n_elements(boxes[0].depth)+0.01, thick=1
		endfor
		bin=0.5
		if keyword_set(leg) then begin
			xyouts, n_elements(boxes.hjd)/2.0, max(!y.range)*0.85, leg, charthick=7, charsize=0.7, align=0.5, color=255
			xyouts, n_elements(boxes.hjd)/2.0, max(!y.range)*0.85, leg, charthick=2.5, charsize=0.7, align=0.5
		endif
		!x.style=7
		!y.style=7
		for i=0, n_elements(boxes[0].depth)-1 do begin
			smultiplot
			loadct, 39
			i_interesting = where(boxes.n[i] gt 0, n_interesting)
			!x.range=[0, 1/sqrt(2*!pi)*bin*n_interesting]*1.3 > keyword_set(log)*0.9
			

			loadct, 39, /silent

			loadct, 39, /silent

			zplothist,uncorrected_sn[i, i_interesting], bin=bin, /rotate, /gauss, pdf_params=[0,1], color=(i+1)*254.0/n_elements(boxes[0].depth)+0.01, thick=2, log=log;, /line_fill, orientation=-45, spacing=0.1

			!p.thick=1
			loadct, 0
			if n_elements(red_variance) gt 0 and ~keyword_set(demo) then begin
				zplothist,  boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i], bin=bin, /rotate, /gauss, pdf_params=[0,1],  thick=1, /line_fill, orientation=45, spacing=0.1, linestyle=1, log=log, color=1;color=(i+1)*254.0/n_elements(boxes[0].depth)+0.01,
			endif
			loadct, 39, /silent
			if ~keyword_set(nobottom) then xyouts, 0, !y.range[0]*0.75, '!C ' + string(format='(F3.1)', boxes[0].duration[i]*24) + ' hr', color=(i+1)*254.0/n_elements(boxes[0].depth), orient=-30
		endfor
		smultiplot, /def
	;!y.range=0
	!x.range=0
	!x.style=0
	!y.style=0
	!p.thick=0
		if keyword_set(eps) then begin
			device, /close
			set_plot, 'x'
			if keyword_set(png) then epstopng, filename, /hide, dpi=200 else epstopdf, filename
		endif
END