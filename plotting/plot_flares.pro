PRO plot_flares, flares, mark=mark, red_variance=red_variance
		!p.charsize=1.5
		smultiplot, [1+n_elements(flares[0].height),1], /init, colw=[1,.1*ones(n_elements(flares[0].height))]
		smultiplot
		sn =  flares.height/flares.height_uncertainty
		i_interesting = where(flares.n gt 0)
		!y.range=reverse(range(sn[i_interesting]))
		if n_elements(red_variance) gt 0 then begin
			uncorrected_sn =  sn
			for i=0, n_elements(flares[0].height)-1 do begin
				uncorrected_sn[i,*] *= sqrt(1.0 + flares[*].n[i]*red_variance[i])
			endfor
		endif

		loadct, 39, /silent
		plot, flares.height[0]/flares.height_uncertainty[0], /nodata, ytitle='Flare S/N', xs=3, xtitle='Flare Center (in gridpoints)', ys=3
		oplot_days, flares.hjd, -!y.range[1], /top
		if keyword_set(mark) then begin
			theta = findgen(21)/20*2*!pi
			usersym, cos(theta), sin(theta)
			for i=0, n_elements(flares[0].height)-1 do plots, mark, flares[mark].height[i]/flares[mark].height_uncertainty[i]/(flares[mark].n[i] gt 0), color=(i+1)*254.0/n_elements(flares[0].height)+0.01, psym=8, symsize=2
			
		endif
		if n_elements(red_variance) gt 0 then begin
			for i=0, n_elements(flares[0].height)-1 do oplot, uncorrected_sn[i,*]/(flares.n[i] gt 0), color=(i+1)*254.0/n_elements(flares[0].height)+0.01, linestyle=1, thick=1
		endif
		for i=0, n_elements(flares[0].height)-1 do oplot, flares.height[i]/flares.height_uncertainty[i]/(flares.n[i] gt 0), color=(i+1)*254.0/n_elements(flares[0].height)+0.01, thick=1
		bin=0.5
		!x.style=7
		!y.style=7
		for i=0, n_elements(flares[0].height)-1 do begin
			smultiplot
			loadct, 39
			n_interesting = n_elements(flares)
			i_interesting = indgen(n_interesting);where(flares.n[i] gt 0, n_interesting)
			!x.range=[0, 1/sqrt(2*!pi)*bin*n_interesting]*1.3

			loadct, 39, /silent

			if n_elements(red_variance) gt 0 then begin
				zplothist, flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i], bin=bin, /rotate, /gauss, pdf_params=[0,1], color=(i+1)*254.0/n_elements(flares[0].height)+0.01, thick=1, /line_fill, orientation=45, spacing=0.1, linestyle=1
			endif
			loadct, 39, /silent
			zplothist, flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i], bin=bin, /rotate, /gauss, pdf_params=[0,1], color=(i+1)*254.0/n_elements(flares[0].height)+0.01, thick=3
			loadct, 39, /silent
			xyouts, 0, !y.range[0], '!C ' + string(format='(F3.1)', flares[0].decay_time[i]*24) + ' hr', color=(i+1)*254.0/n_elements(flares[0].height), orient=-45
		endfor
		smultiplot, /def
	!y.range=0
	!x.range=0
	!x.style=0
	!y.style=0
	!p.thick=0
END