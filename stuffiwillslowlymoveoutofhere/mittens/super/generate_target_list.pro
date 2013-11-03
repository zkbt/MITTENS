

PRO generate_target_list, jason=jason

	if file_test('obs_summary.idl') then restore, 'obs_summary.idl' else obs_summary = load_obs_summaries(ye=11)
	obs_summary = obs_summary[where(obs_summary.tel lt 10)]

	readcol, 'MEarth_Mass_Radius.txt', lspm_string, mass_old, radius_old, pi_literature, err_pi_literature, pi_photo, pi, err_pi, mass_new, radius_new, n_obs, format='A,D,D,D,D,D,D,D,D,D,D,L'
	lspm = fix(stregex(lspm_string, '[0-9]+', /ext))
	distance_originally_adopted = 1.0/pi_photo
	i_hasliterature = where(finite(pi_literature) and err_pi_literature/pi_literature lt 0.1, n_haslitpi)
	if n_haslitpi gt 0 then distance_originally_adopted[i_hasliterature] = 1.0/pi_literature[i_hasliterature]
	
	jason = struct_conv({lspm:lspm, mass_old:mass_old, radius_old:radius_old, distance:1.0/pi, err_distance:err_pi/pi^2, pi:pi, err_pi:err_pi, mass_new:mass_new, radius_new:radius_new, n_obs:n_obs, pi_literature:pi_literature, err_pi_literature:err_pi_literature, pi_photo:pi_photo, distance_originally_adopted:distance_originally_adopted, flat_rescaling:fltarr(n_elements(pi)),err_flat_rescaling:fltarr(n_elements(pi)),sin_rescaling:fltarr(n_elements(pi)),err_sin_rescaling:fltarr(n_elements(pi))})

	; KLUDGE! 9/17/2012!
	readcol, '~/adopted_mearth_params.csv', j_lspm, j_mass, j_radius, j_distmod, j_source, format='I,D,D,D,A'
	for i=0, n_elements(jason) -1 do begin
		i_match = where(j_lspm eq jason[i].lspm, n_match)
		if n_match eq 0 then stop
		jason[i].mass_new = j_mass[i_match]
		jason[i].radius_new = j_radius[i_match]
		jason[i].distance  = 10.0*10^(0.2*(j_distmod[i_match]))
		jason[i].pi  = 1.0/jason[i].distance 

	endfor
	jason = find_funny_parallaxes(jason)
	i_ok = where( jason.err_pi/jason.pi lt 0.5 and jason.distance lt 30 and jason.radius_new lt 0.35, complement=i_bad)
	jason = jason[i_ok]
	print, 'considering ', n_elements(jason), ' of the stars Jason looked at'

	cleanplot
	plot_nd, jason, psym=3

	restore, 'budget_2011.idl'
	rough_flat = load_rough_summaries(ye=11)    
	rough_sin = load_rough_summaries(ye=11, /sin)    
	for i=0, n_elements(jason)-1 do begin
		i_match = where(rough_flat.ls eq jason[i].lspm, n_match)
		if n_match gt 0 then begin
			i_match = i_match[where(rough_flat[i_match].rough.n_points eq max(rough_flat[i_match].rough.n_points))]
			i_match = i_match[0]
			jason[i].flat_rescaling = rough_flat[i_match].rough.rescaling
			jason[i].err_flat_rescaling = rough_flat[i_match].rough.uncertainty_in_rescaling
		endif

		i_match = where(rough_sin.ls eq jason[i].lspm, n_match)
		if n_match gt 0 then begin
			i_match = i_match[where(rough_sin[i_match].rough.n_points eq max(rough_sin[i_match].rough.n_points))]
			i_match = i_match[0]
			jason[i].sin_rescaling = rough_sin[i_match].rough.rescaling
			jason[i].err_sin_rescaling = rough_sin[i_match].rough.uncertainty_in_rescaling
		endif
	endfor

;	representatives = replicate({lspm:0.0, radius:0.0, distance:0.0, rescaling:0.0, rednoise:0.0, n_goodpointings:0, exptime:0.0, medflux:0.0, simulated:stars[0]}, n_elements(stars))

	representatives = replicate({jason:jason[0], flat:rough_flat[0], sin:rough_sin[0]}, n_elements(stars))
	mismatch = bytarr(n_elements(stars))
	for i=0, n_elements(stars)-1 do begin
		i_match = where(jason.lspm eq stars[i].obs.lspm, n_match)
		if n_match eq 1 then representatives[i].jason = jason[i_match] else mismatch[i] += 1
		i_match = where(rough_flat.ls eq stars[i].obs.lspm, n_match)
		if n_match eq 1 then representatives[i].flat = rough_flat[i_match] else mismatch[i] += 2
		i_match = where(rough_sin.ls eq stars[i].obs.lspm, n_match)
		if n_match eq 1 then representatives[i].sin = rough_sin[i_match] else mismatch[i] += 4
	endfor
	i_matched_rep = where(mismatch eq 0, n_matched_rep)
	representatives = representatives[i_matched_rep]
	stars = stars[i_matched_rep]

	i_useful = where(stars.obs.n_goodpointings gt 700 and stars.obs.n_goodpointings lt 1400, n_useful)
	representatives = representatives[i_useful]
	stars = stars[i_useful]

	print, 'using ', n_useful, ' as representatives'

	repsum  = struct_conv({lspm:representatives.jason.lspm, distance:representatives.jason.distance_originally_adopted, radius:representatives.jason.radius_old, $
					sin_rescaling:representatives.jason.sin_rescaling, goodpointings:stars.obs.n_goodpointings})
	print_struct, repsum


	sigma_distance = 1
	sigma_radius = 0.005
	sigma_rescaling = 0.1

	radii = real_triggered_sensitivity.radii
	n_radii = n_elements(radii)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90
	interactive = 1

	simulated_stars = replicate(stars[0], n_elements(jason))
	for i=0, n_elements(jason)-1 do begin
		hyperdistance = 	(representatives.jason.distance_originally_adopted  - jason[i].distance)^2/sigma_distance^2 + $
						(representatives.jason.radius_old  - jason[i].radius_new)^2/sigma_radius^2 + $
					 	(representatives.jason.sin_rescaling - jason[i].sin_rescaling)^2/sigma_rescaling^2 
		i_sort = sort(hyperdistance)

			print, 'THE BEST REPRESENTATIVES FOR'
			print, jason[i].lspm, jason[i].distance, jason[i].radius_new,  jason[i].sin_rescaling
			print, 'ARE PROBABLY'
				if keyword_set(interactive) then 	xplot,1
				if keyword_set(interactive) then 		plot_nd, repsum, dye=alog(hyperdistance), tags=[4,3,2,1]
				if keyword_set(interactive) then 	xplot, 2
			best_guess = stars[0]
			n_nearby = 3
			for j=0, n_nearby-1 do begin
				 print, representatives[i_sort[j]].jason.lspm, representatives[i_sort[j]].jason.distance_originally_adopted, representatives[i_sort[j]].jason.radius_old, representatives[i_sort[j]].jason.sin_rescaling, stars[i_sort[j]].obs.n_goodpointings
			
				if keyword_set(interactive) then 			plot_1starsensitivity, stars[i_sort[j]], radii=real_triggered_sensitivity.radii, periods=real_triggered_sensitivity.period.grid, noerase=j gt 0

			endfor
			i_closest = i_sort[0:n_nearby-1]
			for i_mode = 0,2 do begin
				for i_tag=0, n_tags(best_guess.(i_mode))-1 do begin
					best_guess.(i_mode).(i_tag) = median(stars[i_closest].(i_mode).(i_tag),  dim= n_elements(size(/dim, stars[i_closest].(i_mode).(i_tag))))
				endfor
			endfor
			for i_tag=3,7 do begin
				best_guess.(i_tag) = median(stars[i_closest].(i_tag),   dim=n_elements(size(/dim, stars[i_closest].(i_tag))))
			endfor
			if keyword_set(interactive) then plot_1starsensitivity, best_guess, radii=real_triggered_sensitivity.radii, periods=real_triggered_sensitivity.period.grid, /noerase, thick=5

			i_obs_match = where(obs_summary.lspm eq jason[i].lspm, n_obs_match)
			best_guess.obs.lspm = jason[i].lspm
			best_guess.obs.year = 12
			if n_obs_match gt 0 then begin
				i_obs_match = i_obs_match[where(obs_summary[i_obs_match].n_goodpointings eq max(obs_summary[i_obs_match].n_goodpointings))]
				i_obs_match = 0
				best_guess.obs.tel = obs_summary[i_obs_match].tel
				best_guess.obs.medflux = obs_summary[i_obs_match].medflux
				best_guess.obs.ra = obs_summary[i_obs_match].ra
				best_guess.obs.dec = obs_summary[i_obs_match].dec
			endif
			print
			if question(interactive=interactive, 'Hmm?') then stop
		simulated_stars[i] = best_guess
	endfor
	save, simulated_stars, jason, filename= 'simulated_sensitivities_for_2012.idl', cutoff_trigger, cutoff_phased
	
; 	readcol, 'Absolute_Magnitude_Out_Of_Range.txt', outofrange, format='A'
; 	for i=0, n_elements(lspm_string)-1 do if total(strmatch(outofrange, lspm_string[i])) gt 0 then print_struct, jason[i]
END