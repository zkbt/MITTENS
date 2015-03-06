PRO statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function, justnaive=justnaive, nonaive=nonaive
	cleanplot
	if keyword_set(eps) then begin
		set_plot, 'ps'
		 filename = 'statpaper_sensitivity_lines.eps'
		if keyword_set(justnaive) then filename = 'statpaper_sensitivity_lines_naive.eps' 
		if keyword_set(nonaive) then filename = 'statpaper_sensitivity_lines_nonaive.eps'
		device, filename=filename, /encapsulated, /color, /inches, xsize=7.5, ysize=3, /cmyk
	endif
;	supersampled.period_sensitivity*=4
;	supersampled.temperature_sensitivity*=4
;	naive_supersampled.period_sensitivity*=4
;	naive_supersampled.temperature_sensitivity*=4
	cts = [54, 42, 52, 60, 46, 58]	
	!x.thick=3
	!y.thick=3
	!p.charthick=2
	!p.charsize=0.8
  	radii_to_plot = [4.0,  3.0, 2.5, 2.1, 1.8, 1.6]
  	n_radii = n_elements(radii_to_plot)
  	radii_color = intarr(n_radii); (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii)
  	xy_sens =  reverse(10^(findgen(n_radii)/(n_radii-1.0)*alog10(10)))*2
	smultiplot, [2, 1], /init, xgap =0.02
  	; plot 1D sensitivity in period
	smultiplot, /dox, /doy
	periods = supersampled.period_axis
	loadct, 0, /sil
	plot, [0], /xstyle, ys=3, xrange=[0.5,10], xtitle='Period (days)', /ylog, /xlog, yr=[1, 100],  /nodata, ytitle="MEarth's Sensitivity to Planets!C= # of planets expected if every star !Chosted one planet of given R and {P,T}";!Chow many should have been detected?)"
	x_label = 3- findgen(n_elements(radii_to_plot))*0.4

  	for i=0,n_elements(radii_to_plot)-1 do begin
		loadct, file='~/zkb_colors.tbl',cts[i]
  		y =  bin_sss(naive_supersampled, radii_to_plot[i])
		y_naive = y
		maxes = fltarr(n_elements(y))
		mins = fltarr(n_elements(y)) + 1e7
		for j=0, n_elements(ensemble_of_supersampled)-1 do begin
			y = bin_sss(ensemble_of_supersampled[j], radii_to_plot[i])
			maxes = maxes > y
			mins  = mins < y
;			oplot, periods, y, color=radii_color[i], thick=2, linestyle=0
		endfor
if ~keyword_set(nonaive) then oplot, periods, y_naive, color=radii_color[i], thick=2,  linestyle=2
if ~keyword_set(justnaive) then		polyfill, [periods, reverse(periods)], [maxes, reverse(mins)], color=200, thick=3,  linestyle=2, noclip=0
			
		; BIG KLUDGE TO UNDO AVERAGING!
  		y =  bin_sss(supersampled, radii_to_plot[i])
		angle = 0.0
if ~keyword_set(justnaive) then		oplot, periods, y, color=radii_color[i], thick=4, linestyle=0
		xyouts, x_label[i], interpol(y, periods, x_label[i])*0.88, color=255, goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=-30, align=0.5, charthick=10,charsize=0.7


		xyouts, x_label[i], interpol(y, periods, x_label[i])*0.88, color=radii_color[i], goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=-30, align=0.5, charsize=0.7, charthick=2.5
	endfor		
	loadct, 0
	if n_elements(window_function) gt 0 then oplot, linestyle=3, thick=6, window_function.period.axis, window_function.period.wftp

	x_label = 350 + findgen(n_elements(radii_to_plot))*60

  	; plot 1D sensitivity in temperature
	smultiplot, /dox
	temperatures = supersampled.temperature_axis
	loadct, 0, /sil
	plot, [0], /xstyle, ys=3, xrange=[300,900], xtitle='Zero-Albedo Equilibrium Temperature (K)', /ylog, /xlog, yr=[1, 100],  /nodata, xtickv=reverse([300,400,500,600,700,800,900]), xticks=6, xtickname=reverse(rw([300, 400, 500, 600, 700, 800, 900]))
  	for i=0,n_elements(radii_to_plot)-1 do begin
		loadct, file='~/zkb_colors.tbl',cts[i]
     		y =  bin_sss(naive_supersampled, radii_to_plot[i], /temperature)
		y_naive = y
		maxes = fltarr(n_elements(y))
		mins = fltarr(n_elements(y)) + 1e7
		for j=0, n_elements(ensemble_of_supersampled)-1 do begin
			y = bin_sss(ensemble_of_supersampled[j], radii_to_plot[i], /temperature)
			maxes = maxes > y
			mins  = mins < y
	;		oplot, temperatures, y, color=radii_color[i], thick=2, linestyle=0
		endfor
if ~keyword_set(nonaive) then oplot, temperatures, y_naive, color=radii_color[i], thick=2,  linestyle=2
if ~keyword_set(justnaive) then		polyfill, [temperatures, reverse(temperatures)], [maxes, reverse(mins)], color=200, thick=3,  linestyle=2, noclip=0

		y =  bin_sss(supersampled, radii_to_plot[i], /temperature)
if ~keyword_set(justnaive) then		oplot, temperatures, y, color=radii_color[i], thick=4, linestyle=0
		angle = 0.0
		xyouts, x_label[i], interpol(y, temperatures,x_label[i])*0.88,  color=255, goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=30, align=0.5, charthick=10,charsize=0.7

		xyouts, x_label[i], interpol(y, temperatures,x_label[i])*0.88, color=radii_color[i], goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=30, align=0.5, charsize=0.7, charthick=2.5
	endfor		
	loadct, 0
	if n_elements(window_function) gt 0 then oplot, linestyle=3, thick=6,window_function.temperature.axis, window_function.temperature.wftp
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
	
END
