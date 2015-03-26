PRO process_with_candidate, input_candidate

	common mearth_tools
	common this_star
	candidate_star_dir = star_dir

	if n_elements(input_candidate) eq 0 then begin
		restore, star_dir() + 'phased_candidates.idl'
		input_candidate = best_candidates[0]
	endif

	if tag_exist(input_candidate, 'PERIOD') then candidate = input_candidate else begin
		candidate  = {period:1d8, hjd0:input_candidate.hjd, duration:input_candidate.duration, depth:input_candidate.depth, depth_uncertainty:input_candidate.depth_uncertainty, n_boxes:1, n_points:0, rescaling:1.0, ratio:0.0}
	endelse

	if strmatch(candidate_star_dir, '*combined*') gt 0 then combined=1
	; if combining multiple years, need to clean each separately
	if keyword_set(combined) then begin
		combined_candidate = candidate

		mo = name2mo(star_dir); = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
		if keyword_set(year_of_combination) then begin
			f = file_search(mo_prefix + mo +'/ye'+string(for='(I02)', year_of_combination mod 2000)+'/te*/', /mark)
		endif else begin
			f = file_search(mo_prefix + mo +'/ye*/te*/', /mark)
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

	;all_files = file_search(candidate_star_dir + '*')
	;catch, error_status
	;if error_status ne 0 then begin
	;	mprint, "   couldn't modify the file permissions"
	;endif else begin
	;	file_chmod, /u_read, /u_write, /u_execute, /g_read, /g_write, /g_execute, all_files
	;	catch, /cancel
	;endelse
END
