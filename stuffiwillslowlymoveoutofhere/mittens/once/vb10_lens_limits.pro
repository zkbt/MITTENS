PRO vb10_lens_limits
	restore, 'ls1335/ye11/te02/box_pdf.idl'
	boxes.hjd = boxes.hjd + 0.5 - 50000d
	n_durations = n_elements(boxes[0].duration)
	loadct, 0
	set_plot, 'ps'	
	filename = 'vb10_lensing_limits_from_mearth.eps'
	device, filename=filename, /encap, xsize=7.5, ysize=11, /inches
	!p.charsize=0.5
	smultiplot, [1, n_durations], /init, ygap=0.002
	for i=0, n_durations-1 do begin
		output_filename = 'vb10_mearth_'+string(form='(I02)', boxes[0].duration[i]*24) + 'hours.txt'
		print, output_filename

		openw, lun, output_filename, /get_lun
		printf, lun, '# MEarth limits on box-shaped lensing events for VB10'
		printf, lun, '# results are given assuming box-shaped events, '
		printf, lun, '# with total durations of ' +string(form='(I02)', boxes[0].duration[i]*24) + ' hours'
		printf, lun, '# '
		printf, lun, '#   column [1] = time at mid-"event", quoted as HJD - 2450000.0'
		printf, lun, '#   column [2] = mean magnitude offset of box, relative to overall light curve'
		printf, lun, '#   column [3] = 1sigma uncertainty on mean magnitude offset'
		printf, lun, '#   column [4] = statistical lower limit on the magnitude offset'
		printf, lun, '#			[a lower limit in magnitudes corresponds to upper limit in brightness]'
		printf, lun, '#   		  ("3 sigma limit" = column[2] - 3*column[4] = slightly conservative)'
		printf, lun, '#'
		printf, lun, '# *** All flux units are in magnitudes (negative = brighter). ***'
		printf, lun, '#'

		i_interesting = where(boxes.depth_uncertainty[i] gt 0, n_interesting)
		for j=0, n_interesting-1 do begin
			printf, lun, boxes[i_interesting[j]].hjd, boxes[i_interesting[j]].depth[i], boxes[i_interesting[j]].depth_uncertainty[i],  boxes[i_interesting[j]].depth[i] - boxes[i_interesting[j]].depth_uncertainty[i]*3 
		endfor
		close, lun
		free_lun, lun

		if i mod 2 eq 1 then continue

		smultiplot
		if i eq n_durations-1 then  xtitle='HJD - 2456000.5'
		plot, boxes[i_interesting].hjd,  boxes[i_interesting].depth[i] - boxes[i_interesting].depth_uncertainty[i]*3, yr=[0.04, -0.1], psym=3, /nodata, xtitle=xtitle, xs=3
		hline, 0, color=230
;		!p.color=200
;		!p.symsize=0.001
;		oploterr,  boxes[i_interesting].hjd,  boxes[i_interesting].depth[i], boxes[i_interesting].depth_uncertainty[i], 3
;		!p.color=0
;		!p.symsize=1

		oplot,  boxes[i_interesting].hjd,  boxes[i_interesting].depth[i], psym=3, color=200
		oplot, boxes[i_interesting].hjd,  boxes[i_interesting].depth[i] - boxes[i_interesting].depth_uncertainty[i]*3, psym=3, color=0

		med_limit =  median(boxes[i_interesting].depth[i] - boxes[i_interesting].depth_uncertainty[i]*3)
		hline,med_limit, color=0
		xyouts, max(boxes[i_interesting].hjd), med_limit-0.005, goodtex(latex_confidence(boxes[i_interesting].depth[i] - boxes[i_interesting].depth_uncertainty[i]*3, /auto, /nod)), align=1
		al_legend, box=0, /top, /right, string(form='(F4.1)', 24*boxes[0].duration[i]) + ' hours'
	endfor
	smultiplot, /def
	device, /close
	epstopdf, filename

	filename='vb10_uncertainty_tests.eps'
	device, filename=filename, /encap, xsize=7.5, ysize=3.5, /inches
	d = boxes.duration
	u = boxes.depth_uncertainty
	i = where(u gt 0)
	plot_binned, 24*(d[i] + randomn(seed, n_elements(d[i]))*0.004), u[i], psym=3, xr=[0.5, 13.5], yr=[0, .01], xtitle='Duration of Box (hours)', ytitle=goodtex('1\sigma Uncertainty in Flux Level'), binwidth=1, /med, xs=3
	device, /close
	epstopdf, filename
stop

END