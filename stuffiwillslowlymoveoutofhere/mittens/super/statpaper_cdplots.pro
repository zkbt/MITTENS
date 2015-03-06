PRO statpaper_cdplots, eps=eps
  	common mearth_tools
 trim =1
	cleanplot, /silent
  	!p.charthick=2
	!p.charsize=0.6
  	!x.thick=2
  	!y.thick=2
;	!y.range = [1.,4.5]
;	!x.range = [0.5, 10]
	!y.margin = [3,2]
	!x.margin = [5,0.5]
	if n_elements(stat_radius) eq 0 then stat_radius = [1., 4.5]
	stat_period = [0.5, 20.0]
	stat_temperature = [1500,200]
	; if they're not already defined, set the color scale limits
	x = findgen(101)/100


xlog = 1
ylog=1


if keyword_set(ylog) then begin
	ytickname=(['1','2','3','4'])
	ytickv=[1.,2.,3.,4.]
	yticks = 3
endif



	theta = findgen(22)/20*2*!pi
	usersym, cos(theta), sin(theta), /fill
	c_charsize=0.7
	c_charthick = 2
	c_thick = 2
	shift = 0.15
	
	restore,'cdperiod_inputs.idl'
		stat_period_mask = (inputs.radius_grid ge min(stat_radius) and inputs.radius_grid le max(stat_radius) and inputs.period_grid ge min(stat_period) and inputs.period_grid le max(stat_period))
	period_mask = (inputs.radius_grid ge min(!y.range) and inputs.radius_grid le max(!y.range) and inputs.period_grid ge min(!x.range) and inputs.period_grid le max(!x.range))

	c = merge_chains(search='fitcd_trimmedsuperneptune_*', maxlikely=coef)
	population_period = analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef)*inputs.dlogperiod_grid*inputs.dlogradius_grid
	median_density_ratio = median((1.0/inputs.koi.a_over_rs*(inputs.koi.period/10.)^(2./3.)/.051)^(-3.0))
	transit_prob =0.051*(10.0/inputs.period_grid)^(2.0/3.0)*median_density_ratio^(-1.0/3.0)
	r_fine = r_disc_model_period(inputs.radius_grid, inputs.period_grid, coef=inputs.disc_coef)
	disc_prob = r_fine/(1.0+r_fine)
	nexpected_period = population_period*transit_prob*disc_prob*3897.0
	ndetected_period = inputs.ndetected_period

	scaling = float(ones(n_elements(inputs.period_axis), n_elements(inputs.radius_axis)))
	if keyword_set(xlog) then scaling /= inputs.dlogperiod_grid
	if keyword_set(ylog) then scaling /= inputs.dlogradius_grid
	
	xsize = 5
	ysize = 2.5
	if keyword_set(trim) then xsize = 3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename = 'statpaper_cdperiod_sensitivity.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]

	; plot period sensitivity
  	smultiplot, /dox, /doy
  	loadct, 0, file='~/zkb_colors.tbl'
	contour, transit_prob*disc_prob, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title="Kepler M Dwarf Planet Sensitivity", xs=3, ys=3, xlog=xlog, ylog=ylog, ytickname=ytickname, ytickv=ytickv, yticks=yticks
  	loadct, 55, file='~/zkb_colors.tbl'
	contour, transit_prob*disc_prob, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	if ~keyword_set(trim) then	xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	
	if keyword_set(eps) then begin
		device, /close
	    epstopdf, filename
		filename = 'statpaper_cdperiod_population.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]

	; plot period population	
    smultiplot, /dox, /doy
    	; plot inferred population
		loadct, file='~/zkb_colors.tbl', 0
		contour, population_period*scaling, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /nodata, xs=3,ys=3, xlog=xlog, ylog=ylog, xtitle='Period (days)', ytitle='Planet Size (Earth radii)', title=goodtex("Inferred d^2f/dlogR/dlogP Occurrence"), ytickname=ytickname, ytickv=ytickv, yticks=yticks
		loadct, file='~/zkb_colors.tbl', 59
		contour,  population_period*scaling, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over
		loadct, file='~/zkb_colors.tbl', 0
		r = r_disc_model_period(KOI.rp, KOI.period, coef=inputs.disc_coef)
		eta = r/(1.0+r)
		symsize = sqrt(KOI.a_over_rs/eta)
		symsize = symsize/max(symsize)*4
		theta = findgen(21)/!pi
		usersym, cos(theta), sin(theta), /fill
		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=symsize[i], psym=8, noclip=0
	;	oplot, inputs.period_axis,  coef.b/(1.0 + (coef.pfunny/inputs.period_axis)^coef.beta) 

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	smultiplot, /def

	if keyword_set(eps) then begin
		device, /close
		epstopdf, filename
		filename = 'statpaper_cdperiod_expectation.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]
	; plot number of planets expected (period)
	smultiplot, /dox, /doy
 	; plot expected detections
		loadct, file='~/zkb_colors.tbl', 0
		contour, nexpected_period*scaling, inputs.period_axis, inputs.radius_axis, /fill,ys=3, nlevels=100, /nodata, xs=3, xlog=xlog, ylog=ylog,  xtitle='Period (days)', ytitle='Planet Size (Earth radii)', title=goodtex("Kepler Sensitivity \times Occurrence"), ytickname=ytickname, ytickv=ytickv, yticks=yticks
		loadct, file='~/zkb_colors.tbl', 57
		contour, nexpected_period*scaling, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over
		KOI = inputs.KOI
		loadct, file='~/zkb_colors.tbl', 0
		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=0.5, psym=8, noclip=0	

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	smultiplot, /def


	if keyword_set(eps) then begin
		device, /close
		epstopdf, filename
				filename='statpaper_cdtemperature_sensitivity.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	
		restore,'cdtemperature_inputs.idl'
	c = merge_chains(search='fitcd_temperature_trimmedsuperneptune_*', maxlikely=coef)

	population_temperature = analytical_df2dlogtdlogr(inputs.temperature_grid, inputs.radius_grid, coef=coef)*inputs.dlogtemperature_grid*inputs.dlogradius_grid
	constant = median(1.0/inputs.koi.a_over_rs/inputs.koi.temperature^2)
	transit_prob = constant*inputs.temperature_grid^2;0.051*(10.0/period_grid)^(2.0/3.0)*median_density_ratio^(-1.0/3.0)
	r_fine = r_disc_model_temperature(inputs.radius_grid, inputs.temperature_grid, coef=inputs.disc_coef)
	disc_prob = r_fine/(1.0+r_fine)
	nexpected_temperature = population_temperature*transit_prob*disc_prob*3897.0
	ndetected_temperature = inputs.ndetected_temperature

if keyword_set(xlog) then begin
;	xtickname=(['1500',])
	xtickv=([1500,  1200, 900, 600, 300])
	xtickname=rw(string(xtickv, form='(I)'))
	xticks = n_elements(xtickv)-1
endif
	
	scaling = float(ones(n_elements(inputs.temperature_axis), n_elements(inputs.radius_axis)))
	if keyword_set(xlog) then scaling /= inputs.dlogtemperature_grid
	if keyword_set(ylog) then scaling /= inputs.dlogradius_grid
	
	xsize = 5
	ysize = 2.5
	if keyword_set(trim) then xsize = 3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename = 'statpaper_cdtemperature_sensitivity.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif


	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]

		stat_temperature_mask = (inputs.radius_grid ge min(stat_radius) and inputs.radius_grid le max(stat_radius) and inputs.temperature_grid ge min(stat_temperature) and inputs.temperature_grid le max(stat_temperature))

	!x.range=(stat_temperature)
	temperature_mask = (inputs.radius_grid ge min(!y.range) and inputs.radius_grid le max(!y.range) and inputs.temperature_grid ge min(!x.range) and inputs.temperature_grid le max(!x.range))


	; plot temperature sensitivity
  	smultiplot, /dox, /doy
  	loadct, 0, file='~/zkb_colors.tbl'
	contour, transit_prob*disc_prob, inputs.temperature_axis, inputs.radius_axis, /fill, nlevels=100, xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)', /nodata, title="Kepler M Dwarf Planet Sensitivity", xs=3, ys=3, xlog=xlog, ylog=ylog, ytickname=ytickname, ytickv=ytickv, yticks=yticks, xtickname=xtickname, xtickv=xtickv, xticks=xticks
  	loadct, 55, file='~/zkb_colors.tbl'
	contour, transit_prob*disc_prob, inputs.temperature_axis, inputs.radius_axis, /fill, nlevels=100, /over

	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	if ~keyword_set(trim) then	xyouts, 0.5, 0.5, align=0.5, label
	smultiplot, /def
	
	if keyword_set(eps) then begin
		device, /close
	    epstopdf, filename
		filename = 'statpaper_cdtemperature_population.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]


	; plot temperature population	
    smultiplot, /dox, /doy
    	; plot inferred population
		loadct, file='~/zkb_colors.tbl', 0
		contour, population_temperature*scaling, inputs.temperature_axis, inputs.radius_axis, /fill, nlevels=100, /nodata, xs=3,ys=3, xlog=xlog, ylog=ylog, xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)', title=goodtex("Inferred d^2f/dlogR/dlogT Occurrence"), ytickname=ytickname, ytickv=ytickv, yticks=yticks, xtickname=xtickname, xtickv=xtickv, xticks=xticks
  	loadct, 55, file='~/zkb_colors.tbl'
		loadct, file='~/zkb_colors.tbl', 59
		contour,  population_temperature*scaling, inputs.temperature_axis, inputs.radius_axis, /fill, nlevels=100, /over
		loadct, file='~/zkb_colors.tbl', 0
		r = r_disc_model_temperature(KOI.rp, KOI.temperature, coef=inputs.disc_coef)
		eta = r/(1.0+r)
		symsize = sqrt(KOI.a_over_rs/eta)
		symsize = symsize/max(symsize)*4
		theta = findgen(21)/!pi
		usersym, cos(theta), sin(theta), /fill
		for i=0, n_elements(KOI)-1 do plots, KOI[i].temperature, KOI[i].rp, symsize=symsize[i], psym=8, noclip=0
	;	oplot, inputs.temperature_axis,  coef.b/(1.0 + (coef.pfunny/inputs.temperature_axis)^coef.beta) 


	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	smultiplot, /def

	if keyword_set(eps) then begin
		device, /close
		epstopdf, filename
		filename = 'statpaper_cdtemperature_expectation.eps'
	  	device, filename=filename, /encapsulated, /color, /inches,xsize=xsize,ysize=ysize, /cmyk
	endif
	smultiplot, /init, [2,1], xgap=0.04, ygap=0.055, colwidth=[1, 0.00001 + long(keyword_set(trim) eq 0)]
	; plot number of planets expected (temperature)
	smultiplot, /dox, /doy
 	; plot expected detections
		loadct, file='~/zkb_colors.tbl', 0
		contour, nexpected_temperature*scaling, inputs.temperature_axis, inputs.radius_axis, /fill,ys=3, nlevels=100, /nodata, xs=3, xlog=xlog, ylog=ylog,  xtitle='Equilibrium Temperature (K)!Cassuming 0 albedo', ytitle='Planet Size (Earth radii)', title=goodtex("Kepler Sensitivity \times Occurrence"), ytickname=ytickname, ytickv=ytickv, yticks=yticks, xtickname=xtickname, xtickv=xtickv, xticks=xticks
  	loadct, 55, file='~/zkb_colors.tbl'
		loadct, file='~/zkb_colors.tbl', 57
		contour, nexpected_temperature*scaling, inputs.temperature_axis, inputs.radius_axis, /fill, nlevels=100, /over
		KOI = inputs.KOI
		loadct, file='~/zkb_colors.tbl', 0
		for i=0, n_elements(KOI)-1 do plots, KOI[i].temperature, KOI[i].rp, symsize=0.5, psym=8, noclip=0	


	smultiplot
	plot, [0], xs=4, ys=4, xr=[0,1], yr=[0,1]
	smultiplot, /def
	
	if keyword_set(eps) then begin
		device, /close
		epstopdf, filename
	endif
	
	
	
	


END
