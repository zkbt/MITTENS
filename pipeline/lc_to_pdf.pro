PRO lc_to_pdf, test=test, redtest=redtest, remake=remake, grazing=grazing, highres=highres, keep_flares=keep_flares, timemachine=timemachine, fake_setup=fake_setup, real=real, white=white, squash_flares=squash_flares, crude_lens=crude_lens
;keep_flares = ~keyword_set(squash_flares)
;+
; NAME:
;	lc_to_pdf
; PURPOSE:
;	calculate the PDF of the transit depths, evaluated on a grid of epoch and duration
; CALLING SEQUENCE:
; 	lc_to_pdf, test=test, remake=remake
; INPUTS:
;	(none) - but must have a directory set with set_star
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	*seriously* messes around with the file structure in ls[lspm]/ye[year]/te[tel]/
; RESTRICTIONS:
; EXAMPLE:
;	set_star, 1186, 8, 1
;	lc_to_pdf
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-


	; load up star
	common this_star
	common mearth_tools

	display, /off
	; make text displayed within this procedure is labeled
	procedure_prefix = '[lc_to_pdf]'

	
	; avoid duplication of effort
	if (is_uptodate(star_dir + 'box_pdf.idl', star_dir  + 'target_lc.idl') and ~keyword_set(remake)) then begin
    		mprint, skipping_string, 'lc PDF is up-to-date'
		return
	endif	

	if keyword_set(redtest) then test = 1B

	; load light curve + set up templates and fits
	restore, star_dir +  'target_lc.idl'
	starttime=systime(/sec)
	if keyword_set(timemachine) then begin
		target_lc.okay = (round(target_lc.hjd - mearth_timezone()) le timemachine) and target_lc.okay
		if total(round(target_lc.hjd - mearth_timezone()) le timemachine) eq 0 then begin
			mprint, "ACK! you've gone to the land before time, when running timemachine in lc_to_pdf!"
			return
		endif
	endif

	if keyword_set(test) then target_lc.flux = randomn(seed, n_elements(target_lc.flux))*target_lc.fluxerr*1.5

	unsatisfied_with_harmonic_terms = 1B
	n_harmonics = 1
	while(unsatisfied_with_harmonic_terms) do begin
		templates = generate_templates(target_lc=target_lc, common_mode_lc=common_mode_lc, n_harmonics=n_harmonics)
		if keyword_set(crude_lens) then boxes = generate_boxes(target_lc, durations=(findgen(13)+1.0)/12.0*0.5, res=0.5/24.0) else boxes = generate_boxes(target_lc, highres=highres)
		
		grazers = generate_grazers(target_lc)
		flares = generate_flares(target_lc)	; good that it's sampled only at data points!
		initialized_fit = setup_bayesfit(target_lc, templates, /use_sin, /use_constant)	; not using sin
		; run as a test using (possibily correlated) Gaussian noise
		if keyword_set(test) then begin
			restore, star_dir + 'ext_var.idl'
			original_stddev = stddev(target_lc.flux)
			if keyword_set(redtest) then begin
				xplot
				if keyword_set(white) then target_lc.flux = white
				plot, target_lc.flux, yr=range(target_lc.flux), xr=[0,1000]
				target_lc.flux += 1.5*mean_smooth(target_lc.hjd, target_lc.flux, filtering_time=2.4/24.0) 
				new_stddev = stddev(target_lc.flux)
				target_lc.flux *= original_stddev/new_stddev
; 				print, original_stddev, new_stddev
				oplot, color=250, target_lc.flux
			endif else white = target_lc.flux
			target_lc.flux += templates.common_mode*0.005
			
		endif
	
		; start with priors drawn from thin air
		thinair_priors = generate_priors(initialized_fit, /thinair);/assume_star_is_constant);/
	
		; fit all the data with base systematics + sin + cos + a constant
		season_fit = bayesfit(target_lc, templates, initialized_fit, thinair_priors, residuals=residuals)
		i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
;		print, 'intial guess at parameters'
;		print_struct, season_fit[i_fit]
	
		; decide which additional templates to include, and refit
		if ~keyword_set(timemachine) and ~keyword_set(fake_setup) then templates = add_templates(templates, residuals)
		initialized_fit = setup_bayesfit(target_lc, templates, /use_sin, /use_constant)	; not using sin
		thinair_priors = generate_priors(initialized_fit, /thinair);/assume_star_is_constant);
		season_fit = bayesfit(target_lc, templates, initialized_fit, thinair_priors, residuals=residuals)
	
		other_tel = ~strmatch(star_dir, '*te*')
		; inflate the errors to include common mode uncertainty
		i_cm =  where(strmatch(season_fit.name, 'COMMON_MODE') )
		cm_scale = season_fit[i_cm].coef/season_fit[i_cm].rescaling
		inflated_lc = target_lc
		if ~other_tel then inflated_lc.fluxerr = sqrt(target_lc.fluxerr^2 + (cm_scale*common_mode_lc.fluxerr)^2)
	
		; clip outliers (in both directions), just for setting priors
		clipped_lc = target_lc
		i_outliers = where(abs(residuals/1.48/mad(residuals)) gt 3, n_outliers, complement=i_ok)
		if n_outliers gt 0 then clipped_lc[i_outliers].okay = 0
	
		; choose whether to include a sin term
		use_sin = 0B
		i_sin = where(strmatch(season_fit.name, 'COS*') or strmatch(season_fit.name, 'SIN*'), n_sin)
		if n_sin gt 0 then begin
			sin_significances = season_fit[i_sin].coef/season_fit[i_sin].uncertainty
			if sqrt(total(sin_significances^2)) gt 10 then use_sin=1B
			season_fit[i_sin].solved = use_sin
		endif
		if other_tel then season_fit[i_sin].solved = 0
		clipped_lc.fluxerr = inflated_lc.fluxerr
	
		; fit again, using clipped data, and after having decided on the sin + cos terms
		season_fit = bayesfit(clipped_lc, templates, initialized_fit, thinair_priors, residuals=residuals)
	
	
		initialized_fit = season_fit
	
	
	
		i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
; 		print, 'parameters after deciding on optional templates'
; 		print_struct, season_fit[i_fit]
	
		; make (too) strong systematics priors
		systematics_priors = generate_priors(season_fit, /assume_systematics_are_known, /assume_sin_is_known)
	;	if keyword_set(display) and ~keyword_set(fake) and ~keyword_set(timemachine) then plot_priors, systematics_priors, season_fit
	
		; refit clipped light curve, assuming no night-to-night variability (to get systematics priors) and assuming fake_setup priors (to get night-to-night priors)
		clipped_season_fit_assuming_constant = bayesfit(clipped_lc, templates, initialized_fit, thinair_priors)
		clipped_season_fit_relaxing_constancy = bayesfit(clipped_lc, templates, initialized_fit, systematics_priors)
	
		; absorb the constant term (required for fitting the systematics by themselves) into the nightly offsets
		i_constant = where(strmatch(clipped_season_fit_assuming_constant.name, 'CONSTANT'), n_constant)
		if n_constant eq 1 then begin
			i_nights = where(strmatch(clipped_season_fit_relaxing_constancy.name, 'NIGHT*'), n_nights)
			if n_nights gt 0 then begin
			;	if n_nights gt 1 then print, 'median of nights is ', median(clipped_season_fit_relaxing_constancy[i_nights].coef)
		
				constant = clipped_season_fit_assuming_constant[i_constant].coef
				clipped_season_fit_relaxing_constancy[i_nights].coef += constant
				clipped_season_fit_assuming_constant[i_constant].coef = 0
				clipped_season_fit_assuming_constant[i_constant].is_needed = 0
				clipped_season_fit_assuming_constant[i_constant].uncertainty = 0
				clipped_season_fit_assuming_constant[i_constant].solved = 0
			;	if n_nights gt 1 then print, ' ----> ', median(clipped_season_fit_relaxing_constancy[i_nights].coef)
			endif
		endif
	
		; spliced these two fits together
		spliced_clipped_season_fit = clipped_season_fit_relaxing_constancy
		i_sys = where(season_fit.is_variability eq 0, n_sys)
		if n_sys gt 0 then spliced_clipped_season_fit[i_sys] = clipped_season_fit_assuming_constant[i_sys]
	; 	i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
	; 	print, 'final spliced fit after absorbing constant'
	; 	print_struct, spliced_clipped_season_fit[i_fit]
	
	
		i_xy = where(strmatch(spliced_clipped_season_fit.name, '*_*LC*'), n_xy)
		if n_xy gt 0 then begin
			spliced_clipped_season_fit[i_xy].coef = 0.0
			spliced_clipped_season_fit[i_xy].uncertainty = 0.0005;0.001
			spliced_clipped_season_fit[i_xy].solved = 1
		endif
	
	
		; set priors to those from the SVD vit
		svd_priors = generate_priors(spliced_clipped_season_fit)
		priors = svd_priors
	
		; plot the priors
		if keyword_set(display) and ~keyword_set(fake) and ~keyword_set(timemachine) then  begin
			plot_priors,  svd_priors, spliced_clipped_season_fit 
		endif
; 	
		i_fit = where(spliced_clipped_season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
;		print, 'final spliced fit after absorbing constant'
;int		print_struct, spliced_clipped_season_fit[i_fit]
		
		if keyword_set(timemachine) then begin
			the_night_before=timemachine
			priors_filename = star_dir + fake_trigger_dir + 'timemachine_priors_' + rw(the_night_before) + '.idl'
			;mprint, tab_string, '       saving timemachine priors to ', priors_filename
			save, filename=priors_filename, priors, spliced_clipped_season_fit;, templates, 
			if ~keyword_set(real) then return
		endif
	
	
		; fit for flares
;		if keyword_set(display) and keyword_set(interactive) then xplot, 2, title=star_dir() +'Search for Flare Events', /top
		for i=0, n_elements(flares)-1 do begin
			fit =spliced_clipped_season_fit; initialized_fit
			flares[i] = fit_flare(inflated_lc, templates, fit, priors, flares[i])
		endfor	
	; 	if keyword_set(display) then begin
	; 		cleanplot, /silent
	; 		xplot, /top, 3, title=star_dir() +'S/N for "Flare" Events', xsize=950, ysize=300
	; 		plot_flares, flares
	; 	endif
	
	
	
	
	; 	flare_rednoise_factor = fltarr(n_elements(flares[0].height))
	; 	flare_rednoise_variance = fltarr(n_elements(flares[0].height))
	; 	for i=0, n_elements(flares[0].height)-1 do begin
	; 		i_interesting = where(flares.n[i] gt 0, n_interesting)
	; 		flare_rednoise_factor[i] = 1.48*mad(flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i])
	; 		flare_rednoise_variance[i] = median((flare_rednoise_factor[i]^2-1)/flares[i_interesting].n[i]) > 0
	; 		flares[i_interesting].height_uncertainty[i] *= sqrt(1+flares[i_interesting].n[i]*flare_rednoise_variance[i])
	; 	endfor
	
	
	
		; fit for boxes
;		if keyword_set(display) and keyword_set(interactive) then xplot, 6, title=star_dir() +'Search for Box Events', /top
		for i=0, n_elements(boxes)-1 do begin
			fit =spliced_clipped_season_fit; initialized_fit
			boxes[i] = fit_box(inflated_lc, templates, fit, priors, boxes[i]);, /display )
		endfor
	; 	rescalings = boxes.rescaling
	; 	i_interesting = where(rescalings gt 0, n_interesting)
	; 	median_rescaling = median(rescalings[i_interesting])	
	; 	scaled_boxes = boxes
	; 	for i=0, n_elements(boxes[0].rescaling)-1 do begin
	; 		i_inflate = where(boxes.rescaling[i] lt median_rescaling, n_inflate)
	; 		if n_inflate gt 0 then begin
	; 			boxes[i_inflate].depth_uncertainty[i] *= median_rescaling/boxes[i_inflate].rescaling[i]
	; 		endif
	; 		i_deflate = where(boxes.rescaling[i] gt 5*median_rescaling, n_deflate)
	; 		if n_deflate gt 0 then begin
	; 			boxes[i_deflate].depth_uncertainty[i] *= (5*median_rescaling/boxes[i_deflate].rescaling[i])
	; 		endif
	; 	endfor
		
	; 	if keyword_set(display) then begin
	; 		cleanplot, /silent
	; 		xplot, 7, title=star_dir() +'S/N for "Box" Events', xsize=950, ysize=300
	; 		plot_boxes, boxes
	; 	endif
	
	
	
		; compare flares and boxes, decide between them on a night-by-night basis
	;	if keyword_set(display) then xplot, 8, title='Flares that Seem to Be Necessary', xsize=600, ysize=300
		preflareboxes = boxes
		if keyword_set(squash_flares) then flares_vs_boxes, flares, boxes, inflated_lc, flare_lc=flare_lc, necessary_flares=necessary_flares, templates=templates, fit=fit, priors=priors, i_onflarenight=i_onflarenight, boxeskilledbyflares=boxeskilledbyflares else i_onflarenight = -1
		if keyword_set(keep_flares) then begin
			i = where(boxeskilledbyflares, nf)
			if nf gt 0 then boxes[i].n = preflareboxes[i].n
			if i_onflarenight[0] ne -1 then inflated_lc[i_onflarenight].okay = target_lc[i_onflarenight].okay
			i_onflarenight = -1
		endif
	
		flare_rednoise_variance = fltarr(n_elements(flares[0].height))
		for i=0, n_elements(flares[0].height)-1 do begin
			temp_rednoise = -0.05	
			converged = 0
			while(~converged) do begin
				temp_rednoise += 0.05
				i_interesting = where(flares.n[i] gt 0, n_interesting)
				rednoise_correction = sqrt(1.0 + flares[i_interesting].n[i]*temp_rednoise^2);/(1.0 + temp_rednoise^2)
		;		plothist, flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i]/rednoise_correction, bin=0.1, title=temp_rednoise
		;		oplot_gaussian, bin=0.1, pdf_params=[0,1], flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i]/rednoise_correction
				converged = 1.48*mad(flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i]/rednoise_correction) le 1.0 or temp_rednoise gt 2
			;	print, temp_rednoise, 1.48*mad(flares[i_interesting].height[i]/flares[i_interesting].height_uncertainty[i]/rednoise_correction)
			endwhile
			flare_rednoise_variance[i] = temp_rednoise^2
			flares[i_interesting].height_uncertainty[i] *= rednoise_correction
		endfor
	
		if keyword_set(display) then begin
;			xplot, /top, 4, xsize=500, ysize=200, title=star_dir() +'Flare Red Noise Amplitude'
;			plot,flares[0].decay_time*24, flare_rednoise_variance, psym=-8, xtitle='Duration (hours)', ytitle='Normalized Red Variance (for Flares)', xs=3, thick=3, symsize=2
	
;			cleanplot, /silent
;			xplot, 5, title=star_dir() + 'Red S/N for "Flare" Events', xsize=750, ysize=200, xpos=50, ypos=250
;			plot_flares, flares, red_variance=flare_rednoise_variance
		endif
	
	; 	; if requested, search for grazing transits too!
	; 	if keyword_set(grazing) then begin
	; 		xplot, 14, title='Searching for Grazer Events'
	; 		for i=0, n_elements(grazers)-1 do begin
	; 			fit = spliced_clipped_season_fit; initialized_fitinitialized_fit
	; 			grazers[i] = fit_grazer(inflated_lc, templates, fit, priors, grazers[i])
	; 		endfor	
	; 		if keyword_set(display) then begin
	; 			cleanplot, /silent
	; 			xplot, 9, title='S/N for "Grazer" Events', xsize=950, ysize=300
	; 			plot_grazers, grazers
	; 		endif
	; 		; inflate grazer uncertainties by including enough red noise
	; 		factor = fltarr(n_elements(grazers[0].depth))
	; 		grazer_rednoise_variance = fltarr(n_elements(grazers[0].depth))
	; 		for i=0, n_elements(grazers[0].depth)-1 do begin
	; 			i_interesting = where(grazers.n[i] gt 0, n_interesting)
	; 			factor[i] = 1.48*mad(grazers[i_interesting].depth[i]/grazers[i_interesting].depth_uncertainty[i])
	; 			grazer_rednoise_variance[i] = median((factor[i]^2-1)/grazers[i_interesting].n[i]) > 0
	; 			grazers[i_interesting].depth_uncertainty[i] *= sqrt(1+grazers[i_interesting].n[i]*grazer_rednoise_variance[i])
	; 		endfor
	; 		if keyword_set(display) then begin
	; 			cleanplot, /silent
	; 			xplot, 12, xsize=500, ysize=200, title='Red Noise Amplitude'
	; 			plot,grazers[0].duration*24, grazer_rednoise_variance, psym=-8, xtitle='Duration (hours)',  ytitle='Normalized Red Variance (for grazers)', xs=3, thick=3, symsize=2
	; 			cleanplot, /silent
	; 			xplot, 13, title='Red S/N for "grazer" Events', xsize=950, ysize=300
	; 			plot_grazers, grazers
	; 		endif
	; 		save, filename=star_dir + 'grazer_pdf.idl', grazers, priors, initialized_fit, grazer_rednoise_variance
	; 	endif
	
		; save lots of intermediate things for quickly running the transit injection tests
		if not keyword_set(use_sin) then use_sin =0
		file_mkdir, star_dir + fake_dir
		if keyword_set(fake_setup) then begin
			save, filename=star_dir + 'fakes_setup.idl'
			file_mkdir, star_dir + fake_dir

			return
		endif
	
		; inflate box uncertainties by including enough red noise
	; 	factor = fltarr(n_elements(boxes[0].depth))
	; 	for i=0, n_elements(boxes[0].depth)-1 do begin
	; 		i_suspectforrednoise = where(boxes.n[i] gt 0, n_suspectforrednoise)
	; 		factor[i] = 1.48*mad(boxes[i_suspectforrednoise].depth[i]/boxes[i_suspectforrednoise].depth_uncertainty[i])
	; 		box_rednoise_variance[i] = median((factor[i]^2-1)/(boxes[i_suspectforrednoise].n[i]-factor[i]^2) > 0)
	; 		stop
	; 		boxes[i_suspectforrednoise].depth_uncertainty[i] *= sqrt(1+boxes[i_suspectforrednoise].n[i]*box_rednoise_variance[i])
	; 	endfor
	
		box_rednoise_variance = fltarr(n_elements(boxes[0].depth))
		for i=0, n_elements(boxes[0].depth)-1 do begin
			temp_rednoise = -0.05	
			converged = 0
			while(~converged) do begin
				temp_rednoise += 0.05
				i_interesting = where(boxes.n[i] gt 0, n_interesting)
				rednoise_correction = sqrt(1.0 + boxes[i_interesting].n[i]*temp_rednoise^2);/(1.0 + temp_rednoise^2)
	;  			plothist, boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]/rednoise_correction, bin=0.1, title=temp_rednoise
	;  			oplot_gaussian, bin=0.1, pdf_params=[0,1], boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]/rednoise_correction
	; 			if question("red noise", /int) then stop
				converged = 1.48*mad(boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]/rednoise_correction) le 1.0 or temp_rednoise gt 2
	
			endwhile
			box_rednoise_variance[i] = temp_rednoise^2
			boxes[i_interesting].depth_uncertainty[i] *= rednoise_correction
		endfor
		if keyword_set(display) then begin
			cleanplot, /silent
;			xplot, 10, xsize=500, ysize=200, title=star_dir() +'Red Noise Amplitude'
;			plot,boxes[0].duration*24, box_rednoise_variance, psym=-8, xtitle='Duration (hours)',  ytitle='Normalized Red Variance (for Boxes)', xs=3, thick=3, symsize=2
;			cleanplot, /silent
			xplot, /top, 11, title=star_dir() +'Red S/N for "Box" Events', xsize=750, ysize=200, xpos=50, ypos=250
			plot_boxes, boxes, red_variance=box_rednoise_variance
		endif
		i_resc = where(priors.name eq 'UNCERTAINTY_RESCALING', n_resc)
		if n_resc gt 0 then rescaling = priors[i_resc].coef else rescaling = 0;stop
		
		if (mean(box_rednoise_variance lt 0.3) and rescaling lt 2) or n_harmonics ge 2 then begin
			unsatisfied_with_harmonic_terms = 0
		endif else begin
			unsatisfied_with_harmonic_terms = 1
			n_harmonics+=1
		endelse
	endwhile

	if ~keyword_set(test) then begin
		wait, 1.0 - (systime(/sec) - starttime) > 0.0
		save, filename=star_dir + 'inflated_lc.idl', inflated_lc, templates
		save, filename=star_dir + 'box_pdf.idl', boxes,  priors, spliced_clipped_season_fit, box_rednoise_variance
		save, filename=star_dir + 'spliced_clipped_season_fit.idl', spliced_clipped_season_fit
		save, filename=star_dir + 'flares_pdf.idl', flares, i_onflarenight,  flare_lc, necessary_flares
		save, filename=star_dir + 'rednoise_pdf.idl', box_rednoise_variance, flare_rednoise_variance
		file_delete, star_dir + 'needtomakemarple', /allow
	endif
	if keyword_set(test) then begin
		if keyword_set(redtest) then begin
			save, filename=star_dir + 'rgn_box_pdf.idl', boxes,  priors, spliced_clipped_season_fit, box_rednoise_variance
		endif else begin
			save, filename=star_dir + 'wgn_box_pdf.idl', boxes,  priors, spliced_clipped_season_fit, box_rednoise_variance
		endelse
	endif
END
