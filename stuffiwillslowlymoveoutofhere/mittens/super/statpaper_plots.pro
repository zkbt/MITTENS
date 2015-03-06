PRO statpaper_plots, eps=eps, remake=remake, bumpy=bumpy, talk=talk

	if file_test('statpaper_1_phased_data.idl') eq 0 or keyword_set(remake) then s_1actual = simulate_a_season(1, /phased, /errors, /actual)
;	if file_test('statpaper_1_triggered_data.idl') eq 0 or keyword_set(remake) then s_1trigger = simulate_a_season(1, /trigger, /errors, /actual)
	if file_test('statpaper_upgrade_2_triggered_data.idl') eq 0 or keyword_set(remake) then s_2trigger = simulate_a_season(2, /trigger, /errors, /parallax, /dont)


	; plot a summary of the per-star sensitivities
;	statpaper_sample, /eps

	restore, 'statpaper_1_phased_data.idl'	
	; plot the sensitivity with lines
	statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function, /nonaive
	statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function
	statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function, /justnaive

	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
	supersampled.period_sensitivity /= 4
	supersampled.temperature_sensitivity /= 4

	; calculate the population simulations
;	coolkoi_pop =  simulate_a_population(supersampled, /coolkoi, /bumpy, /nofit)
	coolkoi_smooth_pop =  simulate_a_population(supersampled, /coolkoi, bumpy=bumpy)
;	howard_pop = simulate_a_population(supersampled, /howard)
;	francois_pop =  simulate_a_population(supersampled, /franc, /plot)
;	gj1214b_pop = simulate_a_population(supersampled, /gj1214b)

;	restore, 'statpaper_upgrade_2_triggered_data.idl'
 ;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_howard_',  period_scale=howard_period_scale, temperature_scale=howard_temperature_scale)
 ;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_fressin_', period_scale=francois_period_scale, temperature_scale=francois_temperature_scale)
; 	courtney_hwm = statpaper_howmanyplanets(trim=~keyword_set(talk), supersampled, coolkoi_smooth_pop, label='statpaper_dressing_', period_scale=coolkoi_period_scale, temperature_scale=coolkoi_temperature_scale)

;	for i=0, n_tags(max_period_scale)-1 do max_period_scale.(i) =  francois_period_scale.(i) ;> coolkoi_period_scale.(i)
;	for i=0, n_tags(max_temperature_scale)-1 do max_temperature_scale.(i) = francois_temperature_scale.(i); > coolkoi_temperature_scale.(i)
	
	restore, 'statpaper_1_phased_data.idl'	
	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
	supersampled.period_sensitivity /= 4
	supersampled.temperature_sensitivity /= 4

	ensemble_of_supersampled.period_sensitivity /= 4
	ensemble_of_supersampled.temperature_sensitivity /= 4


;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_1actual_gj1214b_',  eps=eps);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_1actual_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_1actual_fressin_',eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
	courtney_hwm = statpaper_howmanyplanets(trim=~keyword_set(talk),  supersampled, coolkoi_smooth_pop, label='statpaper_1actual_dressing_',  eps=eps, /no_con); period_scale=max_period_scale, temperature_scale=max_temperature_scale, /no_con);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_smooth_hwm = statpaper_howmanyplanets( supersampled, coolkoi_smooth_pop, label='statpaper_1actual_dressing_smooth_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)

;;	restore, 'statpaper_1_triggered_data.idl'
;;	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
;;	supersampled.period_sensitivity /= 4
;;	supersampled.temperature_sensitivity /= 4
;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_1triggered_gj1214b_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_1triggered_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_1triggered_fressin_',eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_pop, label='statpaper_1triggered_dressing_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)



	if n_elements(stat_radius) eq 0 then stat_radius = [1.+keyword_set(talk)*0.5, 4.5]
	stat_period = [0.5, 20.0]
	c = merge_chains(search='fitcd_trimmedsuperneptune_2013*', maxlike=x_initial)
	nit = 1000
	occrate = fltarr(nit)
	yield = fltarr(nit)
	stat_period_mask = (supersampled.radius_grid ge min(stat_radius) and supersampled.radius_grid le max(stat_radius) and supersampled.period_grid ge min(stat_period) and supersampled.period_grid le max(stat_period))
	for i=0, nit-1 do begin
		coef = c[randomu(seed)*n_elements(c)]
		temporary_supersampled = ensemble_of_supersampled[randomu(seed)*n_elements(ensemble_of_supersampled)]
		coolkoi_smooth_pop.period = analytical_df2dlogpdlogr(temporary_supersampled.period_grid, temporary_supersampled.radius_grid, coef=coef)
		occrate[i] = total(coolkoi_smooth_pop.period*temporary_supersampled.dlogperiod_grid*temporary_supersampled.dlogradius_grid*stat_period_mask)
		yield[i] = total(coolkoi_smooth_pop.period*temporary_supersampled.dlogperiod_grid*temporary_supersampled.dlogradius_grid*temporary_supersampled.period_sensitivity*stat_period_mask)
	endfor
	cleanplot
;	xplot, 1, xsize=700, ysize=300, title='Period'
	!p.multi=[0,2,1]
	set_plot, 'ps
	device, filename='period_check.eps', /encapsulated, xsize=10, ysize=5, /inches
	plothist, yield, bin=0.005, title=goodtex('yield = ' + latex_confidence(yield, /aut))
	plothist, occrate, bin=0.005, title=goodtex('occurence = ' + latex_confidence(occrate, /aut))
	device, /close
	epstopdf, 'period_check.eps'
	
	if n_elements(stat_radius) eq 0 then stat_radius = [1., 4.5]
	stat_temperature = [200.,1000.]
	c = merge_chains(search='fitcd_temperature_trimmedsuperneptune_2013*', maxlike=x_initial)
	nit = 1000
	occrate = fltarr(nit)
	yield = fltarr(nit)
	stat_temperature_mask = (supersampled.radius_grid ge min(stat_radius) and supersampled.radius_grid le max(stat_radius) and supersampled.temperature_grid ge min(stat_temperature) and supersampled.temperature_grid le max(stat_temperature))
	for i=0, nit-1 do begin
		coef = c[randomu(seed)*n_elements(c)]
		temporary_supersampled = ensemble_of_supersampled[randomu(seed)*n_elements(ensemble_of_supersampled)]
		coolkoi_smooth_pop.temperature = analytical_df2dlogtdlogr(temporary_supersampled.temperature_grid, temporary_supersampled.radius_grid, coef=coef)
		occrate[i] = total(coolkoi_smooth_pop.temperature*temporary_supersampled.dlogtemperature_grid*temporary_supersampled.dlogradius_grid*stat_temperature_mask)
		yield[i] = total(coolkoi_smooth_pop.temperature*temporary_supersampled.dlogtemperature_grid*temporary_supersampled.dlogradius_grid*temporary_supersampled.temperature_sensitivity*stat_temperature_mask)
	endfor
	cleanplot
;	xplot, 2, xsize=700, ysize=300, title='temperature'
	!p.multi=[0,2,1]
	set_plot, 'ps'
	device, filename='temperature_check.eps', /encapsulated, xsize=10, ysize=5, /inches
	plothist, yield, bin=0.005, title=goodtex('yield = ' + latex_confidence(yield, /aut))
	plothist, occrate, bin=0.005, title=goodtex('occurence = ' + latex_confidence(occrate, /aut))
	device, /close
	epstopdf, 'temperature_check.eps'

xplot, 3
	coolkoi_smooth_pop =  simulate_a_population(supersampled, /coolkoi, bumpy=bumpy)
	courtney_hwm = statpaper_howmanyplanets(trim=~keyword_set(talk), supersampled, coolkoi_smooth_pop, label='statpaper_dressing_', period_scale=coolkoi_period_scale, temperature_scale=coolkoi_temperature_scale)

	max_period_scale = coolkoi_period_scale; francois_period_scale
	max_temperature_scale = coolkoi_temperature_scale;francois_temperature_scale
	restore, 'statpaper_upgrade_2_triggered_data.idl'
	courtney_hwm = statpaper_howmanyplanets(trim=~keyword_set(talk), supersampled, coolkoi_smooth_pop, label='statpaper_dressing_', period_scale=qqq_coolkoi_period_scale, temperature_scale=qqq_coolkoi_temperature_scale)
	for i=0, n_tags(max_period_scale)-1 do max_period_scale.(i) =  max_period_scale.(i) > qqq_coolkoi_period_scale.(i)
	for i=0, n_tags(max_temperature_scale)-1 do max_temperature_scale.(i) = max_temperature_scale.(i) > qqq_coolkoi_temperature_scale.(i)
	




	courtney_smooth_hwm = statpaper_howmanyplanets(exptitle='MEarth Projected Yield!C(detecting planets with single transits)', trim=~keyword_set(talk), /hide, supersampled, coolkoi_smooth_pop, label='statpaper_2triggered_dressing_smooth_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
	restore, 'statpaper_1_phased_data.idl'	
	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
	supersampled.period_sensitivity /= 4
	supersampled.temperature_sensitivity /= 4
	courtney_smooth_hwm = statpaper_howmanyplanets(exptitle='MEarth Early Yield!C(requiring multiple transits for detection)', trim=~keyword_set(talk), /hide, supersampled, coolkoi_smooth_pop, label='statpaper_1actual_dressing_smooth_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)

;	statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function
	; don't convert 4 year sensitivity to one year sensitivity! it's already a 1 year!
;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_2triggered_gj1214b_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_2triggered_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_2triggered_fressin_',eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_pop, label='statpaper_2triggered_dressing_',  eps=eps);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)



	restore, 'statpaper_upgrade_2_triggered_data.idl'

	if n_elements(stat_radius) eq 0 then stat_radius = [1.+keyword_set(talk)*0.5, 4.5]
	stat_temperature = [200.,1000.]
	c = merge_chains(search='fitcd_temperature_trimmedsuperneptune_2013*', maxlike=x_initial)
	nit = 1000
	occrate = fltarr(nit)
	yield = fltarr(nit)
	stat_temperature_mask = (supersampled.radius_grid ge min(stat_radius) and supersampled.radius_grid le max(stat_radius) and supersampled.temperature_grid ge min(stat_temperature) and supersampled.temperature_grid le max(stat_temperature))
	for i=0, nit-1 do begin
		coef = c[randomu(seed)*n_elements(c)]
		temporary_supersampled = ensemble_of_supersampled[randomu(seed)*n_elements(ensemble_of_supersampled)]
		coolkoi_smooth_pop.temperature = analytical_df2dlogtdlogr(temporary_supersampled.temperature_grid, temporary_supersampled.radius_grid, coef=coef)
		occrate[i] = total(coolkoi_smooth_pop.temperature*temporary_supersampled.dlogtemperature_grid*temporary_supersampled.dlogradius_grid*stat_temperature_mask)
		yield[i] = total(coolkoi_smooth_pop.temperature*temporary_supersampled.dlogtemperature_grid*temporary_supersampled.dlogradius_grid*temporary_supersampled.temperature_sensitivity*stat_temperature_mask)
	endfor
	cleanplot
;	xplot, 2, xsize=700, ysize=300, title='temperature'
	!p.multi=[0,2,1]
	set_plot, 'ps'
	device, filename='triggered_temperature_check.eps', /encapsulated, xsize=10, ysize=5, /inches
	plothist, yield, bin=0.005, title=goodtex('yield = ' + latex_confidence(yield, /aut))
	plothist, occrate, bin=0.005, title=goodtex('occurence = ' + latex_confidence(occrate, /aut))
	device, /close
	epstopdf, 'triggered_temperature_check.eps'


 END