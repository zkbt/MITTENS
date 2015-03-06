PRO statpaper_sample, eps=eps
	common mearth_tools
	cleanplot
	years_to_plot = [2008, 2009, 2010, 2011]
	f = file_search('budget_'+string(years_to_plot, form='(I4)')+'.idl')
	restore, f[0]
	theta = findgen(21)/20*2*!pi
	usersym, cos(theta), sin(theta)
			i_radius = value_locate(radii+0.1, 2.7)

	for i=0, n_elements(f) -1 do begin
		restore, f[i]
		if i eq 0 then big_stars = stars else big_stars = [stars, big_stars]
	endfor
	lspms = big_stars.obs.lspm
	unique_lspms = lspms[uniq(lspms, sort(lspms))]
	for i=0, n_elements(unique_lspms)-1 do begin
		i_this = where(big_stars.obs.lspm eq unique_lspms[i], n_this)
		if n_this eq 0 then stop
		i_best = where(big_stars[i_this].phased_ps600[i_radius] eq max(big_stars[i_this].phased_ps600[i_radius] ), n_best); and big_stars[i_this].obs.n_goodpointings gt 100
		if n_best gt 0 then begin
			if n_best gt 1 then i_best = i_best[0]
			if n_elements(final_stars) eq 0 then final_stars = big_stars[i_this[i_best]] else final_stars = [final_stars, big_stars[i_this[i_best]]]
		endif
	endfor

	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename='statpaper_datasample.eps'
		device, filename=filename, xsize=7.5, ysize=4, /inches, /encap, /color, /cmyk
	endif else xplot, 1
	!p.charsize=0.6
	periods_to_detect = [0.5, 1.6, 5.0, 16.0]
	radii_to_detect = reverse([ 2.0, 2.7, 4.0])
	erase
	smultiplot, /init, [n_elements(periods_to_detect), n_elements(radii_to_detect)], xgap=0.005, ygap=0.01, /rowm
	sample_radius = final_stars.phased.radius
	symsize_scale = 70
	sample_symsize = sqrt(final_stars.obs.n_goodpointings)/symsize_scale
	for ip=0, n_elements(periods_to_detect)-1 do begin
		for ir =0, n_elements(radii_to_detect)-1 do begin

		;	i_radius = value_locate(radii+0.1, radii_to_detect[ir])
			sample_period_detection_efficiency = fltarr(n_elements(final_stars))
			for i=0, n_elements(final_stars)-1 do begin
				x = interpol(findgen(n_elements(final_stars[i].phased.period_detection[*,0])),  real_phased_sensitivity.period.grid,  periods_to_detect[ip])
				y = interpol(findgen(n_elements(final_stars[i].phased.period_detection[0,*])), radii, radii_to_detect[ir])
	;;			x = interpol(findgen(n_elements(final_stars[i].phased.period_detection[*,0])),  real_phased_sensitivity.period.grid,  periods_to_detect[ip])
	;;			y = interpol(findgen(n_elements(final_stars[i].phased.period_detection[0,*])), radii, radii_to_detect[ir])
				sample_period_detection_efficiency[i] = interpolate(final_stars[i].phased.period_detection/(final_stars[i].phased.period_transitprob[*]#ones(n_elements(radii))), x, y)
			endfor
			smultiplot
			if ir eq 1 and ip eq 0 then ytitle=goodtex('\eta_{det,i}(R,P) = Per-Star Detection Efficiency') else ytitle =''
			if ip eq 1 and ir eq n_elements(radii_to_detect)-1 then xtitle=goodtex('                            Estimated Stellar Radius (R_{'+ zsymbol(/sun) + '})') else xtitle =''

			loadct, 39
			plot, sample_radius, sample_period_detection_efficiency, /nodata, yr=[0,1], xr=[0.08, 0.39], ys=3, xs=3, xtitle=xtitle, ytitle=ytitle
			for i=0, n_elements(sample_radius)-1 do plots, sample_radius[i], sample_period_detection_efficiency[i], psym=8, symsize=sample_symsize[i], noclip=0
			xpos = 0.38
			ypos = 0.9;(ir+1)*0.3

			cts = [44,56,54,42]
			loadct, cts[ip], file='~/zkb_colors.tbl'
			xyouts, xpos,ypos, goodtex('P='+ rw(string(format='(F4.1)', periods_to_detect[ip])) + ' days') , align=1, charthick=10, color=255
			xyouts, xpos, ypos,  goodtex('P='+ rw(string(format='(F4.1)', periods_to_detect[ip])) + ' days'), align=1, charthick=3, color=0


			cts = [48, 58, 46]
			loadct, cts[ir], file='~/zkb_colors.tbl'
			xyouts, xpos,ypos-0.1, goodtex('R='+string(format='(F3.1)', radii_to_detect[ir]) + 'R_{'+zsymbol(/earth) + '}!C') , align=1, charthick=10, color=255
			xyouts, xpos, ypos-0.1, goodtex('R='+string(format='(F3.1)', radii_to_detect[ir]) + 'R_{'+zsymbol(/earth) + '}!C') , align=1, charthick=3, color=0

	

			if radii_to_detect[ir] eq 2.7 and periods_to_detect[ip] eq 1.6 then begin
				loadct,62, file='~/zkb_colors.tbl'
				vline, 0.2, linestyle=0, thick=5, color=255
				vline, 0.2, linestyle=0, thick=3
				xyouts, .22, .1, orient=90, 'GJ1214b', charthick=7, color=255
				xyouts, .22, .1, orient=90, 'GJ1214b', charthick=3
			endif

			if ir eq n_elements(radii_to_detect)-1 and ip eq n_elements(periods_to_detect)-1 then begin
				loadct, 0
				n_to_plot = reverse([100,300,1000,3000])
				for q=0, n_elements(n_to_plot)-1 do begin
					xpos = 0.275
					ypos = q*.1 + 0.4	
					plots, symsize=sqrt(n_to_plot[q])/symsize_scale, xpos, ypos+0.04, psym=8
					xyouts, xpos, ypos, '  ' + string(for='(I4)', n_to_plot[q]) + ' obs.'
				endfor
			endif
		endfor
	endfor
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		epstopdf, filename
		set_plot, 'x'
	endif

; 	xplot, 2
; 	temperatures_to_detect = [1000, 800, 600, 400]
; 	radii_to_detect = reverse([1.5, 2.0, 2.7, 4.0])
; 	erase
; 	smultiplot, /init, [n_elements(temperatures_to_detect), n_elements(radii_to_detect)], xgap=0.01, ygap=0.01, /rowm
; 	sample_radius = final_stars.phased.radius
; 	sample_symsize = sqrt(final_stars.obs.n_goodpointings)/40
; 	for ip=0, n_elements(temperatures_to_detect)-1 do begin
; 		for ir =0, n_elements(radii_to_detect)-1 do begin
; 		;	i_radius = value_locate(radii+0.1, radii_to_detect[ir])
; 			sample_temperature_detection_efficiency = fltarr(n_elements(final_stars))
; 			for i=0, n_elements(final_stars)-1 do begin
; 				x = interpol(findgen(n_elements(final_stars[i].phased.temp_detection[*,0])),  real_phased_sensitivity.temp.grid,  temperatures_to_detect[ip])
; 				y = interpol(findgen(n_elements(final_stars[i].phased.temp_detection[0,*])), radii, radii_to_detect[ir])
; 				sample_temperature_detection_efficiency[i] = interpolate(final_stars[i].phased.temp_detection/(final_stars[i].phased.temp_transitprob[*]#ones(n_elements(radii))), x, y)
; 			endfor
; 			smultiplot
; 			plot, sample_radius, sample_temperature_detection_efficiency, /nodata, yr=[0,1], xr=[0.08, 0.4], ys=3, xs=3
; 			for i=0, n_elements(sample_radius)-1 do plots, sample_radius[i], sample_temperature_detection_efficiency[i], psym=8, symsize=sample_symsize[i], noclip=0
; 		endfor
; 	endfor
; 	smultiplot, /def

	stop
END