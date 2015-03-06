FUNCTION marginalize_over_star_errors, stars, original_sensitivity, supersampled, ensemble_of_supersampled=ensemble_of_supersampled, phased=phased, triggered=triggered, usejason=usejason

	if keyword_set(usejason) then begin
		readcol, 'MEarth_Mass_Radius_March2013.txt', ja_lspmstring, ja_ra, ja_dec, ja_mass, ja_radius, ja_litpi, ja_litpierr, ja_photpi, ja_newpi, ja_newpierr, ja_newmass, ja_newradius, ja_ndata, ja_vmag, ja_k, ja_mearthmag, format='A,D,D,D,D,D,D,D,D,D,D,D,D,D,D'
		ja_lspm = fix(stregex(/ex, ja_lspmstring, '[0-9]+'))
	endif
	;fractional_radius_error = 0.3
	multiplicity_fraction = 0.34
	single_star_sensitivity = original_sensitivity
 
  	radii_to_plot = [4.0, 3.0, 2.5, 2.0, 1.504]
	n_radii = n_elements(radii_to_plot)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii)
  	xy_sens =  reverse(10^(findgen(n_radii)/(n_radii-1.0)*alog10(10)))
	int = 1

	if keyword_set(phased) then i_mode = where(tag_names(stars) eq 'PHASED')
	if keyword_set(triggered) then i_mode = where(tag_names(stars) eq 'TRIGGERED')

	n_radii = n_elements(original_sensitivity.radii)
	; coefficients for mass vs. radius and luminosity vs. radius from boyajian et al. (2012)
	mr = [0.0135, 1.0718, -0.1297]
	lr = [-3.5822, 6.8639, -7.185, 4.5169] 
	
	n_iterations = 20
	if keyword_set(usejason) then n_iterations = 20
	ensemble_of_supersampled = replicate(supersampled, n_iterations)
	ensemble_of_supersampled.period_sensitivity = 0.0
	ensemble_of_supersampled.temperature_sensitivity = 0.0
	for i_iteration=0, n_elements(ensemble_of_supersampled)-1 do begin
		jcount = 0
		for i_star=0, n_elements(stars)-1 do begin
			mass_of_primary = perturb_stellar_mass(stars[i_star].(i_mode).mass) > 0.1
			if keyword_set(usejason) then begin
				i_match = where(ja_lspm eq stars[i_star].obs.lspm, n_match)
				if n_match eq 1 then mass_of_primary = ja_newmass[i_match[0]] else begin
					 print, "!(!%^&!))*%!",  stars[i_star].obs.lspm,  stars[i_star].obs.n_goodpointings, jcount
					jcount += 1
				endelse
			endif
			mass_factor = mass_of_primary/stars[i_star].(i_mode).mass
	;		mass_factor =  (1.0 + randomn(seed)*fractional_radius_error) > (0.1/stars[i_star].(i_mode).mass)
			mass_of_primary = stars[i_star].(i_mode).mass*mass_factor
			radius_of_primary = mr[0] + mr[1]*mass_of_primary + mr[2]*mass_of_primary^2
	;		luminosity_original = 10^(lr[0] + lr[1]*stars[i_star].(i_mode).radius + lr[2]*stars[i_star].(i_mode).radius^2 + lr[3]*stars[i_star].(i_mode).radius^3)
			luminosity_original = stars[i_star].(i_mode).lum
			luminosity_of_primary = 10^(lr[0] + lr[1]*radius_of_primary + lr[2]*radius_of_primary^2 + lr[3]*radius_of_primary^3)
			radius_factor = radius_of_primary/stars[i_star].(i_mode).radius
			luminosity_factor = luminosity_of_primary/luminosity_original;stars[i_star].(i_mode).lum
			transitprob_factor = radius_factor/mass_factor^(1.0/3.0);radius_factor^(2.0/3.0) ; change in TP for fixed period
			temperature_factor = (luminosity_factor/radius_factor^2)^0.25
			temperature_transitprob_factor = radius_factor/luminosity_factor^0.5;temperature_factor^(-0.5)	; change in TP for fixed temperature
			is_a_binary = randomu(seed) lt multiplicity_fraction
	;		if mass_of_primary le 0.1 then print, mass_of_primary, radius_of_primary, luminosity_of_primary, '(', mass_factor, ')';print, mass_factor, radius_factor, luminosity_factor
			if is_a_binary and ~keyword_set(usejason) then begin
				mass_ratio = randomu(seed)
				mass_of_secondary = mass_ratio*mass_of_primary > 0.1
				radius_of_secondary = mr[0] + mr[1]*mass_of_secondary + mr[2]*mass_of_secondary^2
				luminosity_of_secondary =10^( lr[0] + lr[1]*radius_of_secondary + lr[2]*radius_of_secondary^2 +  lr[3]*radius_of_secondary^3)
				radius_factor *= sqrt((luminosity_of_secondary + luminosity_of_primary)/luminosity_of_primary)
				
				; do i need to account for the fact that the star is also farther away? or is that in the added luminosity?
				new_distance_ratio = sqrt((luminosity_of_secondary + luminosity_of_primary)/luminosity_of_primary)
				new_noiseinplanetaryradii = new_distance_ratio
			;	print, mass_ratio, radius_factor
			endif
	;		print, mass_factor, transitprob_factor, luminosity_factor^.25
		;	print, 'minimum radii: ', radius_factor, ', transit prob:', transitprob_factor
	; 		eta_tran = stars[i].(i_mode).period_transitprob#ones(n_radii)
	; 		eta_disc = stars[i].(i_mode).period_detection/eta_tran
			single_star_sensitivity.period.detection = transitprob_factor*stars[i_star].(i_mode).period_detection
			for j=0, n_elements(single_star_sensitivity.radii)-1 do  single_star_sensitivity.temp.detection[*,j] = temperature_transitprob_factor*interpol(stars[i_star].(i_mode).temp_detection[*,j],   single_star_sensitivity.temp.grid, single_star_sensitivity.temp.grid*luminosity_factor^0.25/mass_factor^(1./6.)) 
;			for j=0, n_elements(single_star_sensitivity.radii)-1 do  single_star_sensitivity.temp.detection[*,j] = interpol( transitprob_factor*stars[i_star].(i_mode).temp_detection[*,j],   single_star_sensitivity.temp.grid, single_star_sensitivity.temp.grid*luminosity_factor^0.25)
			; (need to incorporate mass luminosity relationship into here!)
			single_star_sensitivity.radii = original_sensitivity.radii*radius_factor
			if min(finite(single_star_sensitivity.period.detection)) eq 0 then stop
			ensemble_of_supersampled[i_iteration].period_sensitivity += interpolate_sensitivity(ensemble_of_supersampled[i_iteration].period_grid, ensemble_of_supersampled[i_iteration].radius_grid, sensitivity=single_star_sensitivity)
			ensemble_of_supersampled[i_iteration].temperature_sensitivity += interpolate_sensitivity(ensemble_of_supersampled[i_iteration].temperature_grid, ensemble_of_supersampled[i_iteration].radius_grid, sensitivity=single_star_sensitivity, /temperature)
		endfor

			loadct, 0, /sil
			if  i_iteration eq 0 then plot, [0], /xstyle, ys=3, xrange=[0.5,10], xtitle='Period (days)', /ylog, /xlog, yr=[1, 100],  /nodata, ytitle='MEarth sensitivity'
			loadct, file='~/zkb_colors.tbl',39
			for i=0,n_elements(radii_to_plot)-1 do begin
				y =  bin_sss(ensemble_of_supersampled[i_iteration], radii_to_plot[i])
				oplot, ensemble_of_supersampled[i_iteration].period_axis, y, color=radii_color[i], thick=2, linestyle=0
				angle = 0.0
				xyouts, interpol(ensemble_of_supersampled[i_iteration].period_axis, y, xy_sens[i]), 0.92*xy_sens[i], color=255, goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charthick=15,charsize=0.7
				xyouts, interpol(ensemble_of_supersampled[i_iteration].period_axis, y, xy_sens[i]), 0.92*xy_sens[i], color=radii_color[i], goodtex(string(format='(F3.1)', radii_to_plot[i]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charsize=0.7
			endfor		
	;	if question('aasdg', int=int) then stop
	;	contour, stddev(ensemble_of_supersampled.period_sensitivity, dim=3)/mean(ensemble_of_supersampled.period_sensitivity, dim=3), ensemble_of_supersampled[0].period_axis, ensemble_of_supersampled[0].radius_axis, levels=findgen(200)/1000, /fil
	

	endfor
	if keyword_set(usejason) then print, jcount, ' of ', n_elements(stars), ' were missing parallaxes'
	final_supersampled = ensemble_of_supersampled[0]
	final_supersampled.period_sensitivity = mean(ensemble_of_supersampled.period_sensitivity, dim=3)
	final_supersampled.temperature_sensitivity = mean(ensemble_of_supersampled.temperature_sensitivity, dim=3)
	return, final_supersampled
END