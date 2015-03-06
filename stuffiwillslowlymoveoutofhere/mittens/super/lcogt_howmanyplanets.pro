FUNCTION lcogt_howmanyplanets, sss, pop, label=label, title=title, poplabel=poplabel, simlabel=simlabel, hide=hide, kludge=kludge, period_scale=period_scale, temperature_scale=temperature_scale, eps=eps, stat_radius=stat_radius

  	common mearth_tools
	if ~keyword_set(label) then label = 'lcogt_'

	cleanplot, /silent
  	!p.charthick=2
	!p.charsize=0.6
  	!x.thick=2
  	!y.thick=2
	!y.range = [1.5,4.5]
	!x.range = [0.5, 10]
	!y.margin = [4,4]
	if n_elements(stat_radius) eq 0 then stat_radius = [1.5, 4.5]
	stat_period = [0.5, 20.0]
	stat_temperature = [900,250]
	stat_period_mask = (sss.radius_grid ge min(stat_radius) and sss.radius_grid le max(stat_radius) and sss.period_grid ge min(stat_period) and sss.period_grid le max(stat_period))
	stat_temperature_mask = (sss.radius_grid ge min(stat_radius) and sss.radius_grid le max(stat_radius) and sss.temperature_grid ge min(stat_temperature) and sss.temperature_grid le max(stat_temperature))
	period_mask = (sss.radius_grid ge min(!y.range) and sss.radius_grid le max(!y.range) and sss.period_grid ge min(!x.range) and sss.period_grid le max(!x.range))
	; if they're not already defined, set the color scale limits
	x = findgen(101)/100
	if ~keyword_set(period_scale) then period_scale = {sensitivity:x*max(sss.period_sensitivity*period_mask), population:x*max(pop.period*period_mask), planets_expected:x*max(pop.period*sss.period_sensitivity*sss.dlogperiod_grid*sss.dlogradius_grid*period_mask)}

	theta = findgen(22)/20*2*!pi
	usersym, cos(theta), sin(theta), /fill
	c_charsize=0.7
	c_charthick = 2
	c_thick = 2
	shift = 0.15
	
	period_input_occ_rate = total(pop.period*sss.dlogperiod_grid*sss.dlogradius_grid*stat_period_mask)
  	period_mearth_yield = total(pop.period*sss.dlogperiod_grid*sss.dlogradius_grid*sss.period_sensitivity*stat_period_mask)

	
		; set the contours to annotate with a number of enclosed planets
;	enclosed_planets = reverse([0.03125, 0.0625, 0.125, 0.25, 0.5,1, 2, 4, 8]); 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]);, 0.6, 0.8, 1.0]);
;	enclosed_planets = reverse([0.01, 0.1, 1.0, 10.0]); 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]);, 0.6, 0.8, 1.0]);
;	enclosed_planets = reverse([0.2, 0.4, 0.6, 0.8, 1.0]); 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]);, 0.6, 0.8, 1.0]);
;	enclosed_planets = reverse([0.25, 0.5, 0.75, 1.0]); 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]);, 0.6, 0.8, 1.0]);
	enclosed_planets = reverse([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0]/1.0); 0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 16.0]);, 0.6, 0.8, 1.0]);
;	enclosed_planets = reverse(1000);period_mearth_yield*[0.68, 0.95])
;	print, period_mearth_yield
;	print, enclosed_planets
;	stop
	xsize = 3.5
	ysize = 2.5
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename = 'sensitivity_period_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]
	
	
	

		
	; set up grid of plots
 ; 	smultiplot, /init, [3,2], xgap=0.04, ygap=0.055

	print, label
	print, 'Input occurrence rate = ' + rw(string(form='(F5.2)', period_input_occ_rate)) + ' planets per star.'
	print, '   (with radii spanning ' + string(format='(F7.2 , F7.2)', !y.range) + ', and periods spanning ' + string(format='(F7.2 , F7.2)', !x.range) 
	print, 'MEarth should have found '+ rw(string(period_mearth_yield, form='(F8.3)')) + ' planets if period matters most.'
	

	; plot period sensitivity
  	smultiplot, /dox, /doy
  	loadct, 55, file='~/zkb_colors.tbl'
	contour, (sss.period_sensitivity*(sss.radius_grid gt min(!y.range))), sss.period_axis, sss.radius_axis, /fill, levels=period_scale.sensitivity, xs=3, ys=3
	loadct, 0
	
	if strmatch(label, '*1actual*') then title="MEarth's Previous!CSensitivity to Planets" else title="MEarth's Sensitivity to Planets"
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title=title, ys=3, xs=3
	plots, 1.58*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 1.58, 2.55, '  GJ1214b', charsize=0.5

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
					 	if ~keyword_set(hide) then epstopdf, filename

		filename = 'population_period_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]

	; plot period population	
    smultiplot, /dox, /doy
  	loadct, 59, file='~/zkb_colors.tbl'
	contour, (pop.period)*(sss.radius_grid gt min(!y.range)), sss.period_axis, sss.radius_axis, /fill, levels=period_scale.population, xs=3, ys=3;sss.dlogperiod_grid*sss.dlogradius_grid*
	loadct, 0
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title=goodtex("df^2/dlogR/dlogP!CKepler Occurrence Rate"), ys=3, xs=3
	plots, 1.58*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 1.58, 2.55, '  GJ1214b', charsize=0.5
	;;;;;hline, stat_radius, linestyle=1
	;xyouts, align=1.0, max(stat_period), max(stat_radius)-shift, '!C' + rw(string(form='(F5.2)', period_input_occ_rate)) + ' planets per star.'


	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
					 	if ~keyword_set(hide) then epstopdf, filename

		filename ='expectation_period_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]


	; plot number of planets expected (period)
	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
  	y = pop.period*sss.period_sensitivity*sss.dlogperiod_grid*sss.dlogradius_grid*period_mask
	y = y[reverse(sort(y))]
	cumulative = total(y, /cum)
	i_levels = value_locate(cumulative, enclosed_planets)
	valid = where(i_levels lt n_elements(y)-1, n_valid)
	labeled_levels = y[[i_levels[valid]]]
	labels = string(enclosed_planets, form='(F4.2)')
;	labels[min(valid)] += '!Cplanets'	
  	loadct, 57, file='~/zkb_colors.tbl'
	contour, pop.period*sss.period_sensitivity*sss.dlogperiod_grid*sss.dlogradius_grid*period_mask, sss.period_axis, sss.radius_axis, /fill,levels=period_scale.planets_expected, xs=3, ys=3;
	loadct, 0
	if n_valid gt 0 and mean(labeled_levels[0]) ne total(y) then contour, /overplot, smooth(pop.period*sss.period_sensitivity*sss.dlogperiod_grid*sss.dlogradius_grid, [5,5], /edge_trun), sss.period_axis, sss.radius_axis,levels=labeled_levels,  xs=3, ys=3,  c_thick=c_thick;, c_annot=labels[valid],c_charsize=c_charsize, c_charthick=c_charthick
	plot, sss.period_axis, sss.radius_axis, /noerase, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title='Expected Yield =!CSensitivity x Occurrence', ys=3, xs=3
    plots, 1.58*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 1.58, 2.55, '  GJ1214b', charsize=0.5

	;;;;;hline, stat_radius, linestyle=1
	;xyouts, align=1.0, max(stat_period), max(stat_radius)-shift, '!C'+ rw(string(period_mearth_yield, form='(F8.3)')) + ' expected detections/yr'
;  	if keyword_set(kludge) then !y.range = [2,4]


	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
					 	;if ~keyword_set(hide) then 
					 	epstopdf, filename

		filename='sensitivity_temperature_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]



	!x.range=(stat_temperature)
		temperature_mask = (sss.radius_grid ge min(!y.range) and sss.radius_grid le max(!y.range) and sss.temperature_grid ge min(!x.range) and sss.temperature_grid le max(!x.range))

		if ~keyword_set(temperature_scale) then temperature_scale = {sensitivity:x*max(sss.temperature_sensitivity*temperature_mask), population:x*max(pop.temperature*temperature_mask), planets_expected:x*max(pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid*temperature_mask)}

  	temperature_input_occ_rate = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*stat_temperature_mask)
  	temperature_mearth_yield = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*sss.temperature_sensitivity*stat_temperature_mask)
  	
 	; plot temperature sensitivity
  	smultiplot, /dox, /doy
  	if strmatch(label, '*1actual*') then title="MEarth's Previous!CSensitivity to Planets" else title="MEarth's Sensitivity to Planets"

  	loadct, 55, file='~/zkb_colors.tbl'
	contour, (sss.temperature_sensitivity*(sss.radius_grid gt min(!y.range))), sss.temperature_axis, sss.radius_axis, /fill, levels=temperature_scale.sensitivity, xs=3, ys=3
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)', /nodata, ys=3, xs=3, title=title
	plots, 560*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 590, 2.55, '  GJ1214b', charsize=0.5, align=1


	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
					 	if ~keyword_set(hide) then epstopdf, filename

		filename ='population_temperature_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]


	; plot temperature population	
    smultiplot, /dox, /doy
  	loadct, 59, file='~/zkb_colors.tbl'
	contour, (pop.temperature)*(sss.radius_grid gt min(!y.range)), sss.temperature_axis, sss.radius_axis, /fill, levels=temperature_scale.population, xs=3, ys=3;sss.dlogtemperature_grid*sss.dlogradius_grid*
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)', /nodata,  ys=3, xs=3,title=goodtex("df^2/dlogR/dlogT!CKepler Occurrence Rate")
	plots, 560*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 590, 2.55, '  GJ1214b', charsize=0.5, align=1
	;;;;;hline, stat_radius, linestyle=1

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
	;	xyouts, align=1.0, min(stat_temperature), max(stat_radius)-shift, '!C' + rw(string(form='(F5.2)', temperature_input_occ_rate)) + ' planets per star.'

	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
			 	if ~keyword_set(hide) then 	epstopdf, filename

		filename='expectation_temperature_' + label+'howmanyplanets.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], colw=[1.0, 0.01]


	; plot number of planets expected (temperature)
	smultiplot, /dox, /doy
  	loadct, 65, file='~/zkb_colors.tbl'
  	y = pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid*(sss.radius_grid ge min(!y.range) and sss.radius_grid le max(!y.range) and sss.temperature_grid ge min(!x.range) and sss.temperature_grid le max(!x.range))
	y = y[reverse(sort(y))]
	cumulative = total(y, /cum)
	i_levels = value_locate(cumulative, enclosed_planets)
	valid = where(i_levels lt n_elements(y)-1, n_valid)
	labeled_levels = y[[i_levels[valid]]]
	labels = string(enclosed_planets, form='(F4.2)')
;	labels[min(valid)] += '!Cplanets'	
  	loadct, 57, file='~/zkb_colors.tbl'
	contour, pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid, sss.temperature_axis, sss.radius_axis, /fill,levels=temperature_scale.planets_expected, xs=3, ys=3;
	loadct, 0
		if strmatch(label, '*1actual*') then title="MEarth's Previous!CExpected Yield (=Sensitivity x Occurrence)"
		if strmatch(label, '*2trig*') then title="MEarth + LCOGT!CExpected Yield (=Sensitivity x Occurrence)"

	if n_valid gt 0  and mean(labeled_levels[0]) ne total(y) then contour, /overplot, smooth(pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid, [5,5], /edge_trun), sss.temperature_axis, sss.radius_axis,levels=labeled_levels,  xs=3, ys=3,  c_thick=c_thick;, c_annot=labels[valid],c_charsize=c_charsize, c_charthick=c_charthick
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)',  title=title, /nodata,  ys=3, xs=3
    plots, 560*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 590, 2.55, '  GJ1214b', charsize=0.5, align=1
; uncomment these!
	;;;;;hline, stat_radius, linestyle=1


	print, 'Input occurrence rate = ' + rw(string(form='(F5.2)', temperature_input_occ_rate)) + ' planets per star.'
	print, '   (with radii spanning ' + string(format='(F7.2 , F7.2)', !y.range) + ', and temperatures spanning ' + string(format='(F7.2 , F7.2)', !x.range) 
	print, 'MEarth should have found '+ rw(string(temperature_mearth_yield, form='(F8.3)')) + ' planets if temperature matters most.'
	print
	

  

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	;xyouts, 0.5, 0.5, align=0.5, label
;		xyouts, align=1.0, min(stat_temperature), max(stat_radius)-shift, '!C'+ rw(string(temperature_mearth_yield, form='(F8.3)')) + ' expected detections/yr'

	smultiplot, /def
	if keyword_set(eps) then begin
		  device, /close
	 	;if ~keyword_set(hide) then 
	 	epstopdf, filename
		set_plot, 'x'
  	endif



  return,{period:double(period_mearth_yield), temperature:double(temperature_mearth_yield)}
  
END
