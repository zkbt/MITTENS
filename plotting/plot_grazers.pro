PRO plot_grazers, grazers, mark=mark
		!p.charsize=1.5
		smultiplot, [1+n_elements(grazers[0].depth),1], /init, colw=[1,.1*ones(n_elements(grazers[0].depth))]
		smultiplot
		!y.range=[max( grazers.depth/grazers.depth_uncertainty), min( grazers.depth/grazers.depth_uncertainty)]
		loadct, 39, /silent
		plot, grazers.depth[0]/grazers.depth_uncertainty[0], /nodata, ytitle='grazer S/N', xs=3, xtitle='grazer Center (in gridpoints)', ys=3
		oplot_days, grazers.hjd, -!y.range[1], /top
		if keyword_set(mark) then begin
			theta = findgen(21)/20*2*!pi
			usersym, cos(theta), sin(theta)
			for i=0, n_elements(grazers[0].depth)-1 do plots, mark, grazers[mark].depth[i]/grazers[mark].depth_uncertainty[i]/(grazers[mark].n[i] gt 0), color=(i+1)*254.0/n_elements(grazers[0].depth)+0.01, psym=8, symsize=2
			
		endif
		for i=0, n_elements(grazers[0].depth)-1 do oplot, grazers.depth[i]/grazers.depth_uncertainty[i]/(grazers.n[i] gt 0), color=(i+1)*254.0/n_elements(grazers[0].depth)+0.01
		bin=0.5
		!x.style=7
		!y.style=7
		for i=0, n_elements(grazers[0].depth)-1 do begin
			smultiplot
			loadct, 39
			i_interesting = where(grazers.n[i] gt 0, n_interesting)
			!x.range=[0, 1/sqrt(2*!pi)*bin*n_interesting]*1.3

			zplothist, grazers[i_interesting].depth[i]/grazers[i_interesting].depth_uncertainty[i], bin=bin, /rotate, /gauss, pdf_params=[0,1], color=(i+1)*254.0/n_elements(grazers[0].depth)+0.01, thick=2
			loadct, 39, /silent
			xyouts, 0, !y.range[0], '!C ' + string(format='(F3.1)', grazers[0].duration[i]*24) + ' hr', color=(i+1)*254.0/n_elements(grazers[0].depth), orient=-45
		endfor
		smultiplot, /def
	!y.range=0
	!x.range=0
	!x.style=0
	!y.style=0
	!p.thick=0
END