PRO fit_season
	; take a season of daya, run Bayes fit on it


	
	;xplot, xsize=2000
	loadct, 39
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	; load light curve
	restore, star_dir +  'target_lc.idl'
	templates = generate_templates(target_lc=target_lc)
	transits = generate_transits(target_lc)
	flares = generate_flares(target_lc)

	fit = setup_bayesfit(target_lc, templates)
	season_fit = bayesfit(target_lc, templates, fit)
	priors = generate_priors(season_fit)

	transits = generate_transits(target_lc)
	flares = generate_flares(target_lc)
	fits = replicate(fit[0], n_elements(fit), n_elements(transits))
	
	for i=0, n_elements(transits)-1 do begin
		transits[i] = fit_transit(target_lc, templates, fit, priors, transits[i], /display )
		fits[*,i] = fit
		flares[i] = fit_flare(target_lc, templates, fit, priors, flares[i])

	endfor
	!p.multi=[0,1,3]
	plot, target_lc.flux, ytitle='Uncorrected Flux'
	plot, transits.depth[0]/transits.depth_uncertainty[0], /nodata, yrange=[-20,20]/2, ytitle='Transit Signal to Noise'
	for i=0, n_elements(transits[0].depth)-1 do oplot, transits.depth[i]/transits.depth_uncertainty[i], color=i*255.0/n_elements(transits[0].depth)

	plot, flares.height[0]/flares.height_uncertainty[0], /nodata, yrange=[-20,20]/2, ytitle='Flare Signal to Noise'
	for i=0, n_elements(flares[0].height)-1 do oplot, flares.height[i]/flares.height_uncertainty[i], color=i*255.0/n_elements(flares[0].height)


	help
END	