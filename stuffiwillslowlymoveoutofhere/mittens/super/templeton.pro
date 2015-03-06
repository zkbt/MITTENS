PRO templeton, sss, pop, label=label, title=title, poplabel=poplabel, simlabel=simlabel, hide=hide, kludge=kludge, period_scale=period_scale, temperature_scale=temperature_scale, eps=eps, stat_radius=stat_radius, trim=trim, no_contours=no_contours
eps=1
  	common mearth_tools
	restore, 'statpaper_1_phased_data.idl'	
	sss = supersampled
	pop =  simulate_a_population(supersampled, /coolkoi, bumpy=bumpy)
		
	cleanplot, /silent
  	!p.charthick=2
	!p.charsize=0.6
  	!x.thick=2
  	!y.thick=2
	!y.range = [1.,4.5]
	!x.range = [0.5, 10]
	!y.margin = [3,2]
	!x.margin = [5,0.5]
	if n_elements(stat_radius) eq 0 then stat_radius = [1., 4.5]
	stat_period = [0.5, 20.0]
	stat_temperature = [1000,200]
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
	trim = 1
 temperature_enclosed_planets = [10000000.0, 100000.0]


	xsize = 6.5
	ysize = 2.4
;	if keyword_set(trim) then xsize = 3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename='templeton.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,2], xgap=0.04, ygap=0.055, colwidth=[1, 1], rowh=[1,.28], /rowm
	
	!x.range=(stat_temperature)
	temperature_mask = (sss.radius_grid ge min(!y.range) and sss.radius_grid le max(!y.range) and sss.temperature_grid ge min(!x.range) and sss.temperature_grid le max(!x.range))

	if ~keyword_set(temperature_scale) then temperature_scale = {sensitivity:x*max(sss.temperature_sensitivity*temperature_mask), population:x*max(pop.temperature*temperature_mask), planets_expected:x*max(pop.temperature*sss.temperature_sensitivity*sss.dlogtemperature_grid*sss.dlogradius_grid*temperature_mask)}

  	temperature_input_occ_rate = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*stat_temperature_mask)
  	temperature_mearth_yield = total(pop.temperature*sss.dlogtemperature_grid*sss.dlogradius_grid*sss.temperature_sensitivity*stat_temperature_mask)
  	
 	; plot temperature sensitivity
  	smultiplot, /dox, /doy
  	loadct, 55, file='~/zkb_colors.tbl'
	contour, (sss.temperature_sensitivity*(sss.radius_grid gt min(!y.range))), sss.temperature_axis, sss.radius_axis, /fill, levels=temperature_scale.sensitivity, xs=3, ys=3
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Planet Equilibrium Temperature (K)!Cassuming zero albedo', ytitle='Planet Radius (Earth radii)', /nodata, ys=3, xs=3, title="MEarth's Early Sensitivity to Planets"
	plots, 560*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 590, 2.55, '  GJ1214b', charsize=0.5, align=1
	hz = [278, 228]
	spacing=0.15
	loadct, 0, file='~/zkb_colors.tbl'
	polyfill, [hz[0], hz[0], hz[1], hz[1], hz[0]], [.5, 5, 5, 0.5, 0.5], orient=45, /line_fill, spacing=spacing, color=50, noclip=0
	vline, hz, thick=2, color=50

		xyouts, 285, mean(stat_radius), align=0.5, 'habitable zone', charsize=.8, charthick=2, orient=90

	loadct, 0

	smultiplot
	luminosity = 0.0055
	mass = 0.25
	temp_range = !x.range
	temp_periods = 365.*(((sss.temperature_axis/278.)^(-2)*luminosity^0.5)^3*mass^(-1))^.5
	periods_to_plot = [0.5,1,2,4,8,16, 32]
	xtickn = ['0.5', '1', '2','4','8','16', '32']
	xtickv = interpol(sss.temperature_axis, temp_periods, periods_to_plot)
;	xtickn = (periods_to_plot)
	xticks = n_elements(xtickv+1)
	plot, sss.temperature_axis, sss.temperature_axis, /nodata, xs=7, ys=4

	axis, xaxis=0, xs=3, xtickv=xtickv, xtickn=xtickn, xticks=xticks, xticklen=0.2, xtitle='Planet Period (days)'
	
;	smultiplot, /def
;	if keyword_set(eps) then begin
;		device, /close	
;		
;	 	if ~keyword_set(hide) then epstopdf, filename
;		filename ='templeton_population.eps'
;	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
;	endif
;	smultiplot, /init, [2,2], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)], rowh=[1,.28]


	; plot temperature population	
    smultiplot, /dox, /doy
  	loadct, 59, file='~/zkb_colors.tbl'
	contour, (pop.temperature)*(sss.radius_grid gt min(!y.range)), sss.temperature_axis, sss.radius_axis, /fill, levels=temperature_scale.population, xs=3, ys=3;sss.dlogtemperature_grid*sss.dlogradius_grid*
	loadct, 0
	plot, sss.temperature_axis, sss.radius_axis, /noerase, xtitle='Planet Equilibrium Temperature (K)!Cassuming zero albedo', ytitle='Planet Radius (Earth radii)', /nodata,  ys=3, xs=3,title=goodtex("Planet Occurrence around M Dwarfs!Cderived from the Kepler Mission")
	plots, 560*[1,1], [2.6], psym=8, symsize=0.7, thick=3
	xyouts, 590, 2.55, '  GJ1214b', charsize=0.5, align=1
	;;;;;hline, stat_radius, linestyle=1
	loadct, 0, file='~/zkb_colors.tbl'
	polyfill, [hz[0], hz[0], hz[1], hz[1], hz[0]], [.5, 5, 5, 0.5, 0.5], orient=45, /line_fill, spacing=spacing, color=50, noclip=0
	vline, hz, thick=2, color=50
	loadct, 0
	xyouts, 285, mean(stat_radius), align=0.5, 'habitable zone', charsize=0.8, charthick=2, orient=90

	smultiplot
		plot, sss.temperature_axis, sss.temperature_axis, /nodata, xs=7, ys=4

	axis, xaxis=0, xs=3, xtickv=xtickv, xtickn=xtickn, xticks=xticks, xticklen=0.2, xtitle='Planet Period (days)'


	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
			 	if ~keyword_set(hide) then 	epstopdf, filename
	stop
	endif
  
END