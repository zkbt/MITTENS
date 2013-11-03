

FUNCTION howmanyplanets, sss, pop, label=label, title=title, poplabel=poplabel, simlabel=simlabel, hide=hide, kludge=kludge

  	common mearth_tools
  	radii_to_plot = [4.0, 3.0, 2.5, 2.03]
  	n_radii = n_elements(radii_to_plot)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii)
  	xy_sens =  reverse(10^(findgen(n_radii)/(n_radii-1.0)*alog10(10)))

	if ~keyword_set(label) then label = 'temporary_'

	cleanplot
  	!p.charthick=3
	!p.charsize=0.7
  	!x.thick=3
  	!y.thick=3

;	if keyword_set(eps) then begin
		set_plot, 'ps'
	  	device, filename=label+'howmanyplanets.eps', /encapsulated, /color, /inches,xsize=10,ysize=7.5
;	endif

	; set up grid of plots
  	smultiplot, /init, [3,4], xgap=0.08, ygap=0.04, /rowm
  	if keyword_set(kludge) then !y.range = [2,4]
  	; plot contours 
  	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, sss.period_sensitivity*(sss.radius_grid gt min(!y.range)), sss.period_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title='Simulated Sensitivity', ys=3, xs=3
	
    smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, pop.period*sss.dlogperiod_grid*sss.dlogradius_grid*(sss.radius_grid gt min(!y.range)), sss.period_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title='Assumed Occurrence Rate', ys=3, xs=3
	
	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, pop.period*sss.period_sensitivity*sss.dlogperiod_grid*sss.dlogradius_grid*(sss.radius_grid gt min(!y.range)), sss.period_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title='Sensitivity x Occurrence', ys=3, xs=3
  	  	if keyword_set(kludge) then !y.range = 0

	; MAJOR KLUDGE!
  	period_input_occ_rate = total(pop.period*sss.dlogperiod_grid*sss.dlogradius_grid*(sss.radius_grid gt 2))
  	period_mearth_yield = total(pop.period*sss.dlogperiod_grid*sss.dlogradius_grid*sss.period_sensitivity)

	smultiplot
	plot, [0,1],[0,1], /nodata, xs=4, ys=4
	str = ''
	str += '!C!C'
  	str += 'In the range!C!C'
  	str += '     ' + string(min(sss.period_axis), form='(F3.1)') + " < P < " + $
  			rw(string(max(sss.period_axis), form='(F4.1)')) + '!C'
	str += '     ' + string(min(2), form='(F3.1)') + " < R < " + $
			string(max(sss.radius_axis), form='(F3.1)') + '!C!C'
	str += 'the integrated input occurrence!C'
	str += 'rate is ' + rw(string(form='(F5.2)', period_input_occ_rate)) + ' planets per star !C!C'
	str += '!C'
	str += '     ' + 'MEarth would expect!C'
	str += '     ' + rw(string(period_mearth_yield, form='(F8.3)')) + ' planets per year'
	str += '!C     if period matters most.'
	xyouts, -0.1, 0.9, str

  	if keyword_set(kludge) then !y.range = [2,4]

  	; plot contours 
  	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, sss.temperature_sensitivity*(sss.radius_grid gt min(!y.range)), sss.temperature_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Temperature (K; 0 albedo)', ytitle='Planet Size (Earth radii)', /nodata, title='Simulated Sensitivity', ys=3, xs=3
	
    smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*(sss.radius_grid gt min(!y.range)), sss.temperature_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Temperature (K; 0 albedo)', ytitle='Planet Size (Earth radii)', /nodata, title='Assumed Occurrence Rate', ys=3, xs=3
	
	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
	contour, pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid*(sss.radius_grid gt min(!y.range)), sss.temperature_axis, sss.radius_axis, /fill, nlevels=100, xs=3, ys=3
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Temperature (K; 0 albedo)', ytitle='Planet Size (Earth radii)', /nodata, title='Sensitivity x Occurrence', ys=3, xs=3
  

	if keyword_set(kludge) then !y.range = 0

	; (MAJRO KLUDGE)
  	temperature_input_occ_rate = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*(sss.radius_grid gt 2))
  	temperature_mearth_yield = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*sss.temperature_sensitivity)

	smultiplot
	plot, [0,1],[0,1], /nodata, xs=4, ys=4
	str = ''
	str += '!C!C'
  	str += 'In the range!C!C'
  	str += '     ' + string(min(sss.temperature_axis), form='(I4)') + " < T < " + $
  			rw(string(max(sss.temperature_axis), form='(I4)')) + '!C'
	str += '     ' + string(min(2), form='(F3.1)') + " < R < " + $
			string(max(sss.radius_axis), form='(F3.1)') + '!C!C'
	str += 'the integrated input occurrence!C'
	str += 'rate is ' + rw(string(form='(F5.2)', temperature_input_occ_rate)) + ' planets per star !C!C'
	str += '!C'
	str += '     ' + 'MEarth would expect!C'
	str += '     ' + rw(string(temperature_mearth_yield, form='(F8.3)')) + ' planets per year'
	str += '!C     if temperature matters most.'
	xyouts, -0.1, 0.9, str


  	; plot 1D sensitivity in period
	smultiplot, /dox, /doy
	periods = sss.period_axis
	loadct, 0, /sil
	plot, [0], /xstyle, ys=3, xrange=[0.5,10], xtitle='Period (days)', /ylog, /xlog, yr=[1, 50],  /nodata, ytitle='MEarth sensitivity'
	loadct, file='~/zkb_colors.tbl',39
  	for i=0,n_elements(radii_to_plot)-1 do begin
  		y =  bin_sss(sss, radii_to_plot[i])
		oplot, periods, y, color=radii_color[i], thick=6, linestyle=0
		angle = 0.0
		xyouts, interpol(periods, y, xy_sens[i]), 0.92*xy_sens[i], color=255, goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charthick=15,charsize=0.7
		xyouts, interpol(periods, y, xy_sens[i]), 0.92*xy_sens[i], color=radii_color[i], goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charsize=0.7
	endfor		

  	; plot 1D sensitivity in temperature
	smultiplot, /dox, /doy
	temperatures = sss.temperature_axis
	loadct, 0, /sil
	plot, [0], /xstyle, ys=3, xrange=[200,700], xtitle='Zero-Albedo Equilibrium Temperature (K)', /ylog, /xlog, yr=[1, 50],  /nodata, ytitle='MEarth sensitivity'
	loadct, file='~/zkb_colors.tbl',39
  	for i=0,n_elements(radii_to_plot)-1 do begin
  		y =  bin_sss(sss, radii_to_plot[i], /temperature)
		oplot, temperatures, y, color=radii_color[i], thick=6, linestyle=0
		angle = 0.0
		xyouts, interpol(temperatures, y, xy_sens[i]), 0.92*xy_sens[i], color=255, goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charthick=15,charsize=0.7
		xyouts, interpol(temperatures, y, xy_sens[i]), 0.92*xy_sens[i], color=radii_color[i], goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charsize=0.7
	endfor		







	smultiplot

  	str = ''
  	if keyword_set(poplabel) then str += 'Population drawn from!C     '+poplabel + '!C!C'
  	if keyword_set(simlabel) then str += 'Simulations assuming!C     '+simlabel + '!C'
	plot, [0,1],[0,1], /nodata, xs=4, ys=4
	xyouts, -0.1, 0.9, str

  
	smultiplot, /def
  	device, /close
 	if ~keyword_set(hide) then epstopdf,label+'howmanyplanets.eps'
	set_plot, 'x'
  



  return,{period:double(period_mearth_yield), temperature:double(temperature_mearth_yield)}
  
END