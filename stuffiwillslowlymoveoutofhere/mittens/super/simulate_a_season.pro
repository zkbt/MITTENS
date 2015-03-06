
FUNCTION simulate_a_season, eps=eps, n_tel, original=original, phased=phased, triggered=triggered, resummed=resummed, thrifty=thrifty, parallaxes=parallaxes, realistic=realistic, actual=actual, spot=spot, dontsubtract=dontsubtract, errors=errors, usejason=usejason
	; spit out a supersampled sensitivity estimate for a season's parameters

	common mearth_tools
	; load budget and real sensitivity curves
	restore, 'budget_2011.idl'
	original_radii = radii
	simulated_sensitivity = real_phased_sensitivity

	; set up a super-sampled sensitivity grid
	n_radii = 100
	n_periods = 100
	n_temperatures = n_periods
	if keyword_set(radius_range) then begin
		min_radius = float(min(radius_range))
		max_radius = float(max(radius_range))
	endif else begin
		min_radius = 1.0;min(simulated_sensitivity.radii)
		max_radius = 5.0
	endelse
	dradius = (max_radius- min_radius)/(n_radii-1)
	radius_grid = ones(n_periods)#(min_radius + findgen(n_radii)*dradius)
	dlogradius_grid = dradius/radius_grid*alog10(exp(1))
	radius_axis = (min_radius + findgen(n_radii)*dradius)
	if keyword_set(period_range) then begin
		min_period = float(min(period_range))
		max_period = float(max(period_range))
	endif else begin
		min_period = 0.5
		max_period = 20.0
	endelse
	dperiod = (max_period- min_period)/(n_periods-1)
	period_grid = (min_period + findgen(n_periods)*dperiod)#ones(n_radii)
	dlogperiod_grid = dperiod/period_grid*alog10(exp(1))
	period_axis =(min_period + findgen(n_periods)*dperiod)
	if keyword_set(temperature_range) then begin
		min_temperature = float(min(temperature_range))
		max_temperature = float(max(temperature_range))
	endif else begin
		min_temperature = 200.0
		max_temperature = 1000.0
	endelse
	dtemperature = (max_temperature- min_temperature)/(n_temperatures-1.0)
	temperature_grid = (min_temperature + findgen(n_temperatures)*dtemperature)#ones(n_radii)
	dlogtemperature_grid = dtemperature/temperature_grid*alog10(exp(1))
	temperature_axis =(min_temperature + findgen(n_temperatures)*dtemperature)


; 	supersampled = {period_sensitivity:interpolate_sensitivity(period_grid, radius_grid, 					sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii)), $
; 					temperature_sensitivity:interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temp)*(radius_grid gt min(simulated_sensitivity.radii)), $					

	supersampled = {period_sensitivity:interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))*0.0, $
						temperature_sensitivity:interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temp)*(radius_grid gt min(simulated_sensitivity.radii))*0.0, $	
						radius_grid:radius_grid, dlogradius_grid:dlogradius_grid, radius_axis:radius_axis, dradius:dradius,$
						period_grid:period_grid, dlogperiod_grid:dlogperiod_grid, period_axis:period_axis, dperiod:dperiod,$
						temperature_grid:temperature_grid, dlogtemperature_grid:dlogtemperature_grid, temperature_axis:temperature_axis, dtemperature:dtemperature}





	; set up for phased or triggered sensitivity
	tags = tag_names(stars)
	if keyword_set(phased) then begin
		original_sensitivity =  real_phased_sensitivity
		i_mode = where(tags eq 'PHASED', n)
		if n eq 0 then stop
	endif
	if keyword_set(triggered) then begin
		original_sensitivity = real_triggered_sensitivity
		i_mode = where(tags eq 'TRIGGERED', n)
		if n eq 0 then stop
	endif
	if (~keyword_set(phased) and ~keyword_set(triggered)) or (keyword_set(phased) and keyword_set(triggered)) then begin
		print, "&*)!#%! Please specify whether you're interested in the phased or triggered sensitivity!"
		return, 'sad trombone'
	endif
; 	if keyword_set(original) then begin
; 		simulated_sensitivity.period.detection = original_sensitivity.period.detection/ n_tel
; 		simulated_sensitivity.temp.detection = original_sensitivity.temp.detection/n_tel
; 		simulated_sensitivity.radii = original_sensitivity.radii/n_tel^0.25
; 
; 	endif
; 	if keyword_set(realistic) then begin
; 		simulated_sensitivity =  marginalize_over_star_errors(stars, original_sensitivity, supersampled, phased=phased, triggered=triggered )
; 		stop
; 	endif
; 	if keyword_set(resummed) then begin
; 		simulated_sensitivity.period.detection =  total(stars.(i_mode).period_detection, 3)/n_tel
; 		simulated_sensitivity.temp.detection =  total(stars.(i_mode).temp_detection, 3)/n_tel
; 		simulated_sensitivity.radii = original_sensitivity.radii/n_tel^0.25
; 	endif
	if keyword_set(actual) then begin
		f= file_search('budget_*.idl')
		for i_year=0, n_elements(f)-1 do begin
			restore, f[i_year]
			if i_year eq 0 then allstars = stars else allstars = [allstars, stars]
		endfor
		h = histogram(allstars.obs.lspm, reverse_indices=ri)
		non_overlapping_stars = replicate(stars[0], total(h gt 0))
		count = 0
		for i=0, n_elements(h)-1 do begin
			if h[i] gt 0 then begin
				candidate_stars = allstars[ri[ri[i]:ri[i+1]-1]]
				i_max = where(candidate_stars.phased_ps600[2] eq max(candidate_stars.phased_ps600[2]), n_max)
				if n_max gt 1 then i_max = i_max[0]
				non_overlapping_stars[count] = candidate_stars[i_max]
				count += 1
			endif
		endfor
		stars = non_overlapping_stars
		skiplist = [1186, 3512, 3229, 1803]
		for i=0, n_elements(skiplist)-1 do stars = stars[where(stars.obs.lspm ne skiplist[i])]
		stars = stars[where(stars.obs.n_goodpointings ge 100)]
		simulated_sensitivity = original_sensitivity
		simulated_sensitivity.period.detection =  total(stars.(i_mode).period_detection, 3)/n_tel
		simulated_sensitivity.temp.detection =  total(stars.(i_mode).temp_detection, 3)/n_tel
 		simulated_sensitivity.radii = original_sensitivity.radii/n_tel^0.25
;		simulated_sensitivity.period.detection /= 4 ; years
;		simulated_sensitivity.temp.detection /= 4 ; years

		window_function = {period:{axis:simulated_sensitivity.period.grid, wftp:total(stars.(i_mode).period_window*stars.(i_mode).period_transitprob, 2)/n_tel}, temperature:{axis:simulated_sensitivity.temp.grid, wftp:total(stars.(i_mode).temp_window*stars.(i_mode).temp_transitprob, 2)/n_tel}}
		if keyword_set(errors) then begin
			supersampled =  marginalize_over_star_errors(stars, simulated_sensitivity, supersampled, phased=phased, triggered=triggered, ensemble_of_supersampled=ensemble_of_supersampled, usejason=usejason)
			supersampled.period_sensitivity /= n_tel;n_elements(f)/n_tel
			supersampled.temperature_sensitivity /= n_tel;n_elements(f)/n_tel

			naive_supersampled = supersampled
			naive_supersampled.period_sensitivity = interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))
			naive_supersampled.temperature_sensitivity = interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temperature)*(radius_grid gt min(simulated_sensitivity.radii))
			if keyword_set(phased) then mode = 'phased' else mode = 'triggered'
			save, filename='statpaper_'+rw(n_tel)+'_'+mode+'_data.idl', naive_supersampled, supersampled, ensemble_of_supersampled, window_function
		endif else begin
			; recalculate the supersampled sensitivity
			supersampled.period_sensitivity = interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))
			supersampled.temperature_sensitivity = interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temperature)*(radius_grid gt min(simulated_sensitivity.radii))
		endelse
	endif



	if keyword_set(parallaxes) then begin
		restore, 'budget_2011.idl'
		restore, 'simulated_sensitivities_for_2012.idl'

		if ~keyword_set(dontsubtract) then simulated_stars = subtract_excluded_planets(simulated_stars)
		if keyword_set(spot) then begin
			restore, 'spot_transit_boost.idl'
			roughs = load_rough_fits(ye=11)
			for i=0, n_elements(simulated_stars)-1 do begin
				i_match = where(roughs.ls eq simulated_stars[i].obs.lspm, n_match)
				this_amp = mean(roughs[i_match].amp)
		
				factor = interpol(boost, amplitude, this_amp)
				simulated_stars[i].triggered_ps300 *= factor
				simulated_stars[i].triggered_ps600 *= factor
				simulated_stars[i].phased_ps300 *= factor
				simulated_stars[i].phased_ps600 *= factor
				simulated_stars[i].phased.period_detection *= factor
				simulated_stars[i].phased.temp_detection *= factor
				simulated_stars[i].phased.period_transitprob *= factor
				simulated_stars[i].phased.temp_transitprob *= factor
				simulated_stars[i].triggered.period_detection *= factor
				simulated_stars[i].triggered.temp_detection *= factor
				simulated_stars[i].triggered.period_transitprob *= factor
				simulated_stars[i].triggered.temp_transitprob *= factor
			endfor
		endif

		roughs = load_rough_fits()
		for i=0, n_elements(simulated_stars)-1 do begin
			obs_in_years = intarr(4)
			i08 = where(roughs.ls eq simulated_stars[i].obs.lspm and roughs.ye eq 08, n)
			if n gt 0 then n08 = total(roughs[i08].summary_sin.n_points, /int) else n08 = 0
			i09 = where(roughs.ls eq simulated_stars[i].obs.lspm and roughs.ye eq 09, n)
			if n gt 0 then n09 = total(roughs[i09].summary_sin.n_points, /int) else n09 = 0
			i10 = where(roughs.ls eq simulated_stars[i].obs.lspm and roughs.ye eq 10, n)
			if n gt 0 then n10 = total(roughs[i10].summary_sin.n_points, /int) else n10 = 0
			i11 = where(roughs.ls eq simulated_stars[i].obs.lspm and roughs.ye eq 11, n)
			if n gt 0 then n11 = total(roughs[i11].summary_sin.n_points, /int) else n11 = 0
			if max([n08,n09,n10,n11]) gt 1000 then simulated_stars[i].cost *= 2
		endfor

		; based on the chosen representatives for each star, rank targets by cost
		i_sort = reverse(sort(simulated_stars.TRIGGERED_PS300[2]/simulated_stars.cost))
		i_max = max(where(total(/cum, simulated_stars[i_sort].cost) lt 411.0/n_tel))

	;	print_targets_2012, simulated_stars[i_sort], jason[i_sort], i_max, spot=spot, dontsubtract=dontsubtract, n_tel=n_tel


		stars = simulated_stars[i_sort[0:i_max-1]]
		simulated_sensitivity = original_sensitivity
		simulated_sensitivity.period.detection =  total(stars.(i_mode).period_detection, 3)
		simulated_sensitivity.temp.detection =  total(stars.(i_mode).temp_detection, 3)
 		simulated_sensitivity.radii = original_sensitivity.radii/n_tel^0.25
		window_function = {period:{axis:simulated_sensitivity.period.grid, wftp:total(stars.(i_mode).period_window*stars.(i_mode).period_transitprob, 2)}, temperature:{axis:simulated_sensitivity.temp.grid, wftp:total(stars.(i_mode).temp_window*stars.(i_mode).temp_transitprob, 2)}}

		if keyword_set(errors) then begin
			supersampled =  marginalize_over_star_errors(stars, simulated_sensitivity, supersampled, phased=phased, triggered=triggered, ensemble_of_supersampled=ensemble_of_supersampled, usejason=usejason)
	;		supersampled.period_sensitivity /= n_tel;n_elements(f)/n_tel
	;		supersampled.temperature_sensitivity /= n_tel;n_elements(f)/n_tel

			naive_supersampled = supersampled
			naive_supersampled.period_sensitivity = interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))
			naive_supersampled.temperature_sensitivity = interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temperature)*(radius_grid gt min(simulated_sensitivity.radii))
			if keyword_set(phased) then mode = 'phased' else mode = 'triggered'
			save, filename='statpaper_upgrade_'+rw(n_tel)+'_'+mode+'_data.idl', naive_supersampled, supersampled, ensemble_of_supersampled, window_function
		endif else begin
			; recalculate the supersampled sensitivity
			supersampled.period_sensitivity = interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))
			supersampled.temperature_sensitivity = interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temperature)*(radius_grid gt min(simulated_sensitivity.radii))
		endelse



		; calculate the survey sensivity by summing the cheapest stars
		simulated_sensitivity.period.detection =  total(simulated_stars[i_sort[0:i_max-1]].(i_mode).period_detection, 3)
		simulated_sensitivity.temp.detection =  total(simulated_stars[i_sort[0:i_max-1]].(i_mode).temp_detection, 3)
		simulated_sensitivity.radii = original_sensitivity.radii/n_tel^0.25

		if keyword_set(errors) then begin
			supersampled =  marginalize_over_star_errors(stars[i_sort[0:i_max-1]], simulated_sensitivity, supersampled, phased=phased, triggered=triggered, ensemble_of_supersampled=ensemble_of_supersampled)
		endif else begin
	
			; recalculate the supersampled sensitivity
			supersampled.period_sensitivity = interpolate_sensitivity(period_grid, radius_grid, sensitivity=simulated_sensitivity)*(radius_grid gt min(simulated_sensitivity.radii))
			supersampled.temperature_sensitivity = interpolate_sensitivity(temperature_grid, radius_grid, sensitivity=simulated_sensitivity, /temperature)*(radius_grid gt min(simulated_sensitivity.radii))
		endelse
	endif
			
	return, supersampled
END
; 	for t=1,8 do begin
; 		boosted_real_triggered_sensitivity = real_triggered_sensitivity
; 		boosted_real_triggered_sensitivity.period.detection /= t
; 		boosted_real_triggered_sensitivity.temp.detection /= t
; 		radii = original_radii/t^0.25
; 	 	triggered.actual[t-1] = howmanyplanets(boosted_real_triggered_sensitivity, label='super_real_triggered_'+rw(t)+'tel_', title=goodtex("                               triggered (5\sigma Single Event) Sensitivity in 2011-2012, assuming " + rw(t) + "telescopes per star"))
; 	endfor
; 	radii = original_radii
; 
; ;	plot_sensitivity1d, boosted_real_triggered_sensitivity, /trigger,  5, label='super_real_triggered_', title=goodtex("                            Actual Triggering (5\sigma Single Event) Sensitivity in 2011-2012")
; 
; 	; stack the deck in our favor, by only taking the most favorable stars
; 	noise_summary_filename = 'noise_cloud_summary.idl'
; 	restore, noise_summary_filename
; 	
; 	if file_test( 'polite_fake_sensitivities.idl') eq 0 then begin
; 		n_fake = 10
; 		fake_phased_sensitivity = replicate(real_phased_sensitivity, n_fake)
; 		fake_triggered_sensitivity = replicate(real_triggered_sensitivity, n_fake)
; 		polite = noise_cloud.rms/noise_cloud.predicted_rms lt 1.2 and noise_cloud.rednoise lt 0.5
; 	
; 		for i_fake =0, n_fake-1 do begin
; 			fake_phased_sensitivity[i_fake].period.detection =0
; 			fake_phased_sensitivity[i_fake].temp.detection =0
; 			fake_triggered_sensitivity[i_fake].period.detection =0
; 			fake_triggered_sensitivity[i_fake].temp.detection =0
; 			n_pointings_used = 0L
; 			while(n_pointings_used lt n_total_good_planet_pointing) do begin
; 				i = long(randomu(seed)*n_elements(planobs))
; 				i_noise = where(strmatch(noise_cloud.star_dir, star_dirs[i] +'*'), n_match_noise)
; 				i_phased = where(strmatch(phased_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_phased)
; 				i_triggered = where(strmatch(triggered_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_triggered)
; 	
; 				if  n_match_noise eq 0 or  n_match_phased eq 0 or n_match_triggered eq 0 then begin
; 					print, star_dirs[i], n_match_noise,  n_match_phased , n_match_triggered
; 					continue
; 				endif
; 				if planobs[i].n_goodpointings gt 500 and polite[i_noise] then begin
; 					fake_phased_sensitivity[i_fake].period.detection +=  phased_per_star_sensitivity[i_phased].period_detection
; 					fake_phased_sensitivity[i_fake].temp.detection += phased_per_star_sensitivity[i_phased].temp_detection
; 					fake_triggered_sensitivity[i_fake].period.detection += triggered_per_star_sensitivity[i_triggered].period_detection
; 					fake_triggered_sensitivity[i_fake].temp.detection += triggered_per_star_sensitivity[i_triggered].temp_detection
; 					
; 					this_star = {obs:planobs[i], noise:noise_cloud[i_noise], phased:phased_per_star_sensitivity[i_phased], triggered:triggered_per_star_sensitivity[i_triggered]}
; 					if n_elements(stars) eq 0 then stars = this_star else stars = [stars, this_star]
; 					n_pointings_used += planobs[i].n_goodpointings
; 				endif
; 			endwhile	
; 		endfor
; 		polite_fake_triggered_sensitivity = fake_triggered_sensitivity[0]
; 		polite_fake_triggered_sensitivity.period.detection = mean(fake_triggered_sensitivity.period.detection, dim=3)
; 		polite_fake_triggered_sensitivity.temp.detection = mean(fake_triggered_sensitivity.temp.detection, dim=3)
; 		polite_fake_phased_sensitivity = fake_phased_sensitivity[0]
; 		polite_fake_phased_sensitivity.period.detection = mean(fake_phased_sensitivity.period.detection, dim=3)
; 		polite_fake_phased_sensitivity.temp.detection = mean(fake_phased_sensitivity.temp.detection, dim=3)
; 	
; 		save, polite_fake_phased_sensitivity, polite_fake_triggered_sensitivity, filename='polite_fake_sensitivities.idl'
; 	endif else restore, 'polite_fake_sensitivities.idl'
; 	for t=1,8 do begin
; 		boosted_polite_fake_phased_sensitivity = polite_fake_phased_sensitivity
; 		boosted_polite_fake_phased_sensitivity.period.detection /= t
; 		boosted_polite_fake_phased_sensitivity.temp.detection /= t
; 		radii = original_radii/t^0.25
; 	 	phased.polite[t-1] = howmanyplanets(boosted_polite_fake_phased_sensitivity, label='super_polite_phased_'+rw(t)+'tel_', title=goodtex("                                 Fake Phased (8\sigma) Sensitivity (choosing polite stars), assuming " + rw(t) + "telescopes per star"))
; 	endfor
; 	for t=1,8 do begin
; 		boosted_polite_fake_triggered_sensitivity = polite_fake_triggered_sensitivity
; 		boosted_polite_fake_triggered_sensitivity.period.detection /= t
; 		boosted_polite_fake_triggered_sensitivity.temp.detection /= t
; 		radii = original_radii/t^0.25
; 	 	triggered.polite[t-1] = howmanyplanets(boosted_polite_fake_triggered_sensitivity, label='super_polite_triggered_'+rw(t)+'tel_', title=goodtex("                              Fake Triggering (5\sigma Single Event) Sensitivity  (choosing polite stars), assuming " + rw(t) + "telescopes per star"))
; 	endfor
; 
; 

;	plot_sensitivity1d, polite_fake_phased_sensitivity, label='super_fake_phased', 5, /trig, title=goodtex('                               Fake Phased (8\sigma) Sensitivity (choosing "polite" stars)')
;	plot_sensitivity1d, polite_fake_triggered_sensitivity, label='super_fake_triggered', 8, title=goodtex('                            Fake Triggering (5\sigma Single Event) Sensitivity  (choosing "polite" stars)')

	
; 	if file_test( 'sorted_fake_sensitivities.idl') eq 0 then begin
; 		; fake it choosing the most sensitive stars
; 		n_fake = 1
; 		fake_phased_sensitivity = replicate(real_phased_sensitivity, n_fake)
; 		fake_triggered_sensitivity = replicate(real_triggered_sensitivity, n_fake)
; 		polite = noise_cloud.rms/noise_cloud.predicted_rms lt 1.2 and noise_cloud.rednoise lt 0.5
; 		r = 2
; 		
; 		set_plot, 'ps'
; 		device, filename = 'super_sorted_stars_used.eps', /encap, /color, xsize=5, ysize=3, /inches
; 		loadct, 0
; 		plot, (planobs.n_goodpointings), triggered_ps300[*,r]/(planobs.n_goodpointings), /xlog, title = string(radii[r], form ='(F3.1)') + ' Earth radii', /nodata, xr=[10, 10000]
; 		loadct, 55, file='~/zkb_colors.tbl'
; 		oplot,  (planobs.n_goodpointings), triggered_ps300[*,r]/(planobs.n_goodpointings), psym=1, color=250
; 		i_sorted = reverse(sort(triggered_ps600[*,r]/(planobs.n_goodpointings)))
; 			
; 		for i_fake =0, n_fake-1 do begin
; 			fake_phased_sensitivity[i_fake].period.detection =0
; 			fake_phased_sensitivity[i_fake].temp.detection =0
; 			fake_triggered_sensitivity[i_fake].period.detection =0
; 			fake_triggered_sensitivity[i_fake].temp.detection =0
; 			n_pointings_used = 0L
; 			count = 0
; 			while(n_pointings_used lt n_total_good_planet_pointing) do begin
; 				i = i_sorted[count/3]
; 				i_noise = where(strmatch(noise_cloud.star_dir, star_dirs[i] +'*'), n_match_noise)
; 				i_phased = where(strmatch(phased_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_phased)
; 				i_triggered = where(strmatch(triggered_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_triggered)
; 	
; 				if  n_match_noise eq 0 or  n_match_phased eq 0 or n_match_triggered eq 0 then begin
; 					print, star_dirs[i], n_match_noise,  n_match_phased , n_match_triggered
; 					count += 1
; 					continue
; 				endif
; 	;			if planobs[i].n_goodpointings gt 500 and polite[i_noise] then beginplanobs[i_sorted[0:count/2]].n_goodpointings,  triggered_ps600[i_sorted[0:count/2],r]/(planobs[i_sorted[0:count/2]].n_goodpointings), psym=4, symsize=2
; 					fake_phased_sensitivity[i_fake].period.detection +=  phased_per_star_sensitivity[i_phased].period_detection
; 					fake_phased_sensitivity[i_fake].temp.detection += phased_per_star_sensitivity[i_phased].temp_detection
; 					fake_triggered_sensitivity[i_fake].period.detection += triggered_per_star_sensitivity[i_triggered].period_detection
; 					fake_triggered_sensitivity[i_fake].temp.detection += triggered_per_star_sensitivity[i_triggered].temp_detection
; 					
; 					this_star = {obs:planobs[i], noise:noise_cloud[i_noise], phased:phased_per_star_sensitivity[i_phased], triggered:triggered_per_star_sensitivity[i_triggered]}
; 					if n_elements(stars) eq 0 then stars = this_star else stars = [stars, this_star]
; 					n_pointings_used += planobs[i].n_goodpointings
; 	;			endif
; 				count += 1
; 			endwhile	
; 		endfor
; 		sorted_fake_phased_sensitivity = fake_phased_sensitivity
; 		sorted_fake_triggered_sensitivity = fake_triggered_sensitivity
; 		save,sorted_fake_phased_sensitivity , sorted_fake_triggered_sensitivity, filename =  'sorted_fake_sensitivities.idl'
; 	endif else restore, 'sorted_fake_sensitivities.idl'
; 	
; ;	plots, planobs[i_sorted[0:count/3]].n_goodpointings,  triggered_ps300[i_sorted[0:count/3],r]/(planobs[i_sorted[0:count/3]].n_goodpointings), psym=4, color=250
; ;	device, /close
; 	epstopdf, 'super_sorted_stars_used.eps'
; 
; ;	plot_sensitivity1d, sorted_fake_phased_sensitivity, label='super_fake_phased_sorted', 5, /trig, title=goodtex('                               Fake Phased (8\sigma) Sensitivity (choosing "sorted" stars)')
; ;	plot_sensitivity1d, sorted_fake_triggered_sensitivity, label='super_fake_triggered_sorted', 8, title=goodtex('                            Fake Triggering (5\sigma Single Event) Sensitivity  (choosing "sorted" stars)')
; 	for t=1,8 do begin
; 		boosted_sorted_fake_phased_sensitivity = sorted_fake_phased_sensitivity
; 		boosted_sorted_fake_phased_sensitivity.period.detection /= t
; 		boosted_sorted_fake_phased_sensitivity.temp.detection /= t
; 		radii = original_radii/t^0.25
; 	 	phased.sorted[t-1] = howmanyplanets(boosted_sorted_fake_phased_sensitivity, label='super_sorted_phased_'+rw(t)+'tel_', title=goodtex("                                 Fake Phased (8\sigma) Sensitivity (choosing sorted stars), assuming " + rw(t) + "telescopes per star"))
; 	endfor
; 	for t=1,8 do begin
; 		boosted_sorted_fake_triggered_sensitivity = sorted_fake_triggered_sensitivity
; 		boosted_sorted_fake_triggered_sensitivity.period.detection /= t
; 		boosted_sorted_fake_triggered_sensitivity.temp.detection /= t
; 		radii = original_radii/t^0.25
; 	 	triggered.sorted[t-1] = howmanyplanets(boosted_sorted_fake_triggered_sensitivity, label='super_sorted_triggered_'+rw(t)+'tel_', title=goodtex("                              Fake Triggering (5\sigma Single Event) Sensitivity  (choosing sorted stars), assuming " + rw(t) + "telescopes per star"))
; 	endfor
; 
; 	set_plot, 'ps'
; 	device, filename='planetsperyear.eps', /encap, /color, xsize=10, ysize=5, /inches, decomposed=1
; 	!p.thick=3
; 	!p.multi= [0,2,1]
; 	loadct, 0
; 	plot, [0], xr=[1,8], xs=3, yr=[0,2], xtitle='# of telescopes', ytitle='# of planets/year (Phased)'
; 	loadct, 39
; 	for i=0, n_tags(phased)-1 do oplot, color =i*254.0/n_tags(phased), indgen(8)+1, phased.(i)
; 
; 
; 	plot, [0], xr=[1,8], xs=3, yr=[0,2], xtitle='# of telescopes', ytitle='# of planets/year (Triggered)'
; 	loadct, 39
; 	for i=0, n_tags(phased)-1 do oplot, color =i*254.0/n_tags(phased), indgen(8)+1, phased.(i)
; 	al_legend, box=0, colors=indgen(n_tags(phased))*254.0/n_tags(phased), tag_names(phased), linestyle=0
; 	device, /close
; 	epstopdf, 'planetsperyear.eps'
; 	
; stop
