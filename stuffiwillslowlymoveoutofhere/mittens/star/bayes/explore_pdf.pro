PRO explore_pdf, which, diag=diag, eps=eps, fake=fake, anonymous=anonymous, transit_number=transit_number, octopus=octopus, hide=hide, vartools=vartools, external_dir, trimtransits=trimtransits, longperiod=longperiod


	diag=1
	common mearth_tools
	common this_star
	if keyword_set(external_dir) then begin
	;	file_copy, star_dir + 'candidates_pdf.idl',  star_dir + 'backup_candidates_pdf.idl'
		if keyword_set(octopus) then file_copy, external_dir + 'octopus_candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over else file_copy, external_dir + 'candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over
	endif
	; always use the star_dir that was set before running explore_pdf
	candidate_star_dir = star_dir
	if strmatch(candidate_star_dir, '*combined*') gt 0 then begin
		combined=1
		if strmatch(candidate_star_dir, '*ye*') then year_of_combination = long(stregex(/extract, stregex(/extrac, candidate_star_dir, 'ye[0-9]+'), '[0-9]+'))
	endif
	printl
	print, 'exploring ', candidate_star_dir
	printl

	if keyword_set(octopus) then candidates_filename = 'octopus_candidates_pdf.idl' else if keyword_set(vartools) then candidates_filename='vartools_bls.idl' else candidates_filename = 'candidates_pdf.idl'
	if keyword_set(external_dir) then candidates_filename = 'temp_candidates_pdf.idl'
	; select the candidate to explore
	if file_test(star_dir + candidates_filename) eq 0 then begin
		mprint, skipping_string, ' no candidate pdf was found!'
		return
	endif
	restore, candidate_star_dir + candidates_filename
	if keyword_set(vartools) then best_candidates = bls
	
	nothing = best_candidates[0]
	nothing.period = 1d8
	nothing.hjd0=0
	nothing.duration =0.02
	nothing.depth =0
	nothing.depth_uncertainty =0
;	nothing.n_boxes=0
	nothing.n_points=0
	nothing.rescaling=1
	best_candidates = [best_candidates, nothing]
	if not keyword_set(which) then begin
		print_struct, best_candidates
		which = question(/number, /int, 'which candidate would you like to explore?')
	;	print_struct, best_candidates[which]
	endif



	candidate = best_candidates[which]
	; if combining multiple years, need to clean each separately
	if keyword_set(combined) then begin
		combined_candidate = candidate

		ls = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
		if keyword_set(year_of_combination) then begin
			f = file_search('ls'+string(format='(I04)', ls) +'/ye'+string(for='(I02)', year_of_combination mod 2000)+'/te*/', /mark)
		endif else begin
			f = file_search('ls'+string(format='(I04)', ls) +'/ye*/te*/', /mark)
		endelse
		f  = f[ where(file_test(f + 'box_pdf.idl'))]
		file_copy, /over, f[0]+'jmi_file_prefix.idl', candidate_star_dir + 'jmi_file_prefix.idl'
		file_copy, /over, f[0]+'aperture.idl', candidate_star_dir + 'aperture.idl', /allow

		; loop over years, make files in each subdirectory
		for i=0, n_elements(f)-1 do begin
			star_dir = f[i]
			lcs = pdf_to_lc(combined_candidate)
			this_tel = long(stregex(/ext, stregex(/ext, star_dir, 'te[0-9]+'), '[0-9]+'))
			restore, f[i] + 'raw_target_lc.idl'
			if i eq 0 then big_raw_target_lc = target_lc else big_raw_target_lc = [big_raw_target_lc, target_lc]
			restore, f[i] + 'raw_ext_var.idl'
			if i eq 0 then big_raw_ext_var = ext_var else big_raw_ext_var = [big_raw_ext_var, ext_var]
			raw_tel_array = this_tel*ones(n_elements(ext_var))
			if i eq 0 then big_raw_tel_array = raw_tel_array else big_raw_tel_array = [big_raw_tel_array, raw_tel_array]
			restore, f[i] + 'ext_var.idl'
			if i eq 0 then big_ext_var = ext_var else big_ext_var = [big_ext_var, ext_var]
			restore, f[i] + 'inflated_lc.idl'
			if i eq 0 then big_inflated_lc = inflated_lc else big_inflated_lc = [big_inflated_lc, inflated_lc]
			restore, f[i] + 'variability_lc.idl'
			if i eq 0 then big_variability_lc = variability_lc else big_variability_lc = [big_variability_lc, variability_lc]
			if i eq 0 then big_uncertainty_variability_model = uncertainty_variability_model else big_uncertainty_variability_model = [big_uncertainty_variability_model, uncertainty_variability_model]
			if i eq 0 then big_uncertainty_overall_model = uncertainty_overall_model else big_uncertainty_overall_model = [big_uncertainty_overall_model, uncertainty_overall_model]
			restore, f[i] + 'cleaned_lc.idl'
			if i eq 0 then big_in_an_intransit_box = in_an_intransit_box else big_in_an_intransit_box = [big_in_an_intransit_box, in_an_intransit_box]
			if i eq 0 then big_cleaned_lc = cleaned_lc else big_cleaned_lc = [big_cleaned_lc, cleaned_lc]
			if i eq 0 then  segments_boundaries = n_elements(cleaned_lc) else segments_boundaries = [segments_boundaries,  n_elements(cleaned_lc) + max(segments_boundaries)]
; 			help, cleaned_lc, inflated_lc, variability_lc , ext_var
; 			help, big_cleaned_lc, big_inflated_lc, big_variability_lc, big_ext_var
; stop
		endfor
		; save files
		candidate = combined_candidate
		ext_var = big_ext_var
		save, filename=candidate_star_dir + 'ext_var.idl', ext_var, candidate
		inflated_lc = big_inflated_lc
		save, filename=candidate_star_dir + 'inflated_lc.idl', inflated_lc, candidate, segments_boundaries
		variability_lc = big_variability_lc
		uncertainty_variability_model = big_uncertainty_variability_model
		uncertainty_overall_model = big_uncertainty_overall_model
		save, filename=candidate_star_dir + 'variability_lc.idl', variability_lc, candidate, uncertainty_variability_model, uncertainty_overall_model
		cleaned_lc = big_cleaned_lc
		in_an_intransit_box = big_in_an_intransit_box
		save, filename=candidate_star_dir + 'cleaned_lc.idl', cleaned_lc, candidate, in_an_intransit_box
		ext_var = big_raw_ext_var
		save, filename=candidate_star_dir + 'raw_ext_var.idl', ext_var, candidate
		target_lc = big_raw_target_lc
		save, filename=candidate_star_dir + 'raw_target_lc.idl', target_lc, candidate
		raw_tel_array = big_raw_tel_array
		save, filename=candidate_star_dir + 'raw_tel_array.idl', raw_tel_array
		star_dir = candidate_star_dir
	endif else begin
		lcs = pdf_to_lc(candidate, vartools=vartools)
	endelse

	if keyword_set(hide) then return
	if ~keyword_set(fake) then print_candidate, candidate



; 	screensize = get_screen_size()
; 
; 
; 
; 	; plot the boxes
; 	cleanplot, /silent
; 	xsize = screensize[0]/3
; 	ysize= xsize/3
; 	xpos = screensize[0] - xsize
; 	ypos = screensize[1] ;- screensize[0]/4.5
; 	xplot, 15, title=star_dir() + ' + S/N of hypothetical individual transits', xsize=xsize, ysize=ysize, xpos=xpos , ypos=ypos
; 	restore, star_dir() + 'box_pdf.idl'
; 	restore, star_dir() + 'cleaned_lc.idl'
; 	restore, star_dir() + 'variability_lc.idl'
; 	plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=candidate
; 	
; 		; plot the residuals
; 	cleanplot, /silent
; 	loadct, 0, /silent
; 	smultiplot, /def
; 	xsize = screensize[0]/3
; 	ysize= xsize/1.5
; 	ypos = screensize[1]-  ysize - screensize[0]/3/3
; 	xpos = screensize[0] - xsize
; 
; 	xplot, xsize=xsize, ysize=ysize,  16, title=star_dir + ' + correlations', xpos=xpos, ypos=ypos, top=top
; 	plot_residuals, /top


	
; 
; 	cleanplot, /silent
; 	xplot, 2
; 	lc_plot,  eps=eps, anonymous=anonymous;, diag=diag, /top
; 	
; 	cleanplot, /silent
; 	xplot, 3
; 	lc_plot, /time, eps=eps, anonymous=anonymous;, diag=diag, /top
; 	
; 	cleanplot, /silent
; ; 	xplot, 4
; ; 	lc_plot, /time, /phased, eps=eps, anonymous=anonymous;, diag=diag, /top
; 
; 	xplot, 6
; 	periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1, 100], sin_params=sin_params
; 	
; 

	inspect, best_candidates[which], diag=diag, transit_number=transit_number, eps=eps, sin=sin_params, longperiod=longperiod
;	lc_events, best_candidates[which], diag=diag, transit_number=transit_number, eps=eps, sin=sin_params


END

