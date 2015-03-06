PRO aas2013_plots, eps=eps, remake=remake

	if file_test('statpaper_1_phased_data.idl') eq 0 or keyword_set(remake) then s_1actual = simulate_a_season(1, /phased, /errors, /actual)
	if file_test('statpaper_1_triggered_data.idl') eq 0 or keyword_set(remake) then s_1trigger = simulate_a_season(1, /trigger, /errors, /actual)
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
	coolkoi_smooth_pop =  simulate_a_population(supersampled, /coolkoi);, bumpy=bumpy)
;	coolkoi_smooth_pop =  simulate_a_population(supersampled, /coolkoi, /bumpy)
;	howard_pop = simulate_a_population(supersampled, /howard)
;	francois_pop =  simulate_a_population(supersampled, /franc, /plot)
;	gj1214b_pop = simulate_a_population(supersampled, /gj1214b)

	restore, 'statpaper_upgrade_2_triggered_data.idl'
 ;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_howard_',  period_scale=howard_period_scale, temperature_scale=howard_temperature_scale)
 ;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_fressin_', period_scale=francois_period_scale, temperature_scale=francois_temperature_scale)
 	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_smooth_pop, label='talk_dressing_', period_scale=coolkoi_period_scale, temperature_scale=coolkoi_temperature_scale)

	max_period_scale = coolkoi_period_scale; francois_period_scale
	max_temperature_scale = coolkoi_temperature_scale;francois_temperature_scale
;	for i=0, n_tags(max_period_scale)-1 do max_period_scale.(i) =  francois_period_scale.(i) ;> coolkoi_period_scale.(i)
;	for i=0, n_tags(max_temperature_scale)-1 do max_temperature_scale.(i) = francois_temperature_scale.(i); > coolkoi_temperature_scale.(i)
	
	restore, 'statpaper_1_phased_data.idl'	
	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
	supersampled.period_sensitivity /= 4
	supersampled.temperature_sensitivity /= 4
;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_1actual_gj1214b_',  eps=eps);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_1actual_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_1actual_fressin_',eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_pop, label='statpaper_1actual_dressing_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
	courtney_smooth_hwm = statpaper_howmanyplanets( supersampled, coolkoi_smooth_pop, label='talk_1actual_dressing_smooth_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)

	restore, 'statpaper_1_triggered_data.idl'
	; convert 4 year sensitivity to one year sensitivity (after plotting it with lines)
	supersampled.period_sensitivity /= 4
	supersampled.temperature_sensitivity /= 4
;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_1triggered_gj1214b_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_1triggered_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_1triggered_fressin_',eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_pop, label='statpaper_1triggered_dressing_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)

	restore, 'statpaper_upgrade_2_triggered_data.idl'
	statpaper_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, naive_supersampled=naive_supersampled, final_stars=final_stars, eps=eps, window_function=window_function
	; don't convert 4 year sensitivity to one year sensitivity! it's already a 1 year!
;	gj1214b_hwm = statpaper_howmanyplanets( supersampled, gj1214b_pop, label='statpaper_2triggered_gj1214b_',  eps=eps, /hide);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	howard_hwm = statpaper_howmanyplanets( supersampled, howard_pop, label='statpaper_2triggered_howard_',  eps=eps, /hide, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	francois_hwm = statpaper_howmanyplanets( supersampled, francois_pop, label='statpaper_2triggered_fressin_',eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
;	courtney_hwm = statpaper_howmanyplanets( supersampled, coolkoi_pop, label='statpaper_2triggered_dressing_',  eps=eps);, period_scale=max_period_scale, temperature_scale=max_temperature_scale)
	courtney_smooth_hwm = statpaper_howmanyplanets( supersampled, coolkoi_smooth_pop, label='statpaper_2triggered_dressing_smooth_',  eps=eps, period_scale=max_period_scale, temperature_scale=max_temperature_scale)


 END