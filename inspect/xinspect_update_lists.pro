FUNCTION stringify_candidate, candidate
	str = rw('P='+string(candidate.period, form='(F12.6)')) + ' days, ' + rw(string(candidate.depth/candidate.depth_uncertainty, form='(F6.2)')) + ' sigma'
	i = where(candidate.period gt 1000, n)
	if n gt 0 then str[i] = '(nothing)'
	return, str
END

FUNCTION stringify_box, box
	str = rw('D='+string(box.depth, form='(F12.4)')) + ' mag., ' + rw(string(box.depth/box.depth_uncertainty, form='(F6.2)')) + ' sigma'
;	i = where(box.period gt 1000, n)
;	if n gt 0 then str[i] = '(nothing)'
	return, str
END


PRO xinspect_update_lists, input_object=input_object
	common xinspect_common
	common this_star
	common mearth_tools
	; CLEAN THIS UP!
	octopus = 1
	diag=1

	if keyword_set(external_dir) then begin
	;	file_copy, star_dir + 'candidates_pdf.idl',  star_dir + 'backup_candidates_pdf.idl'
		if keyword_set(octopus) then file_copy, external_dir + 'octopus_candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over else file_copy, external_dir + 'candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over
	endif
	; always use the star_dir that was set before running explore_pdf
	candidate_star_dir = star_dir()	; CLEAN THIS UP!
	octopus = 1
	diag=1

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
	nothing  = {period:1d8, hjd0:0.0d, duration:0.02, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0}

	if file_test(star_dir + candidates_filename) eq 0 then begin
		;mprint, skipping_string, ' no candidate pdf was found!'
		;return
	endif else begin
		restore, candidate_star_dir + candidates_filename
		if keyword_set(vartools) then best_candidates = bls
	endelse


	if n_elements(best_candidates) eq 0 then best_candidates = nothing else best_candidates = [best_candidates, nothing]
;	if not keyword_set(which) then begin
;		print_struct, best_candidates
;		which = question(/number, /int, 'which candidate would you like to explore?')
;	;	print_struct, best_candidates[which]
;	endif

	if strmatch(candidate_star_dir, '*combined*') gt 0 then begin
		combined=1
		if strmatch(candidate_star_dir, '*ye*') then year_of_combination = long(stregex(/extract, stregex(/extrac, candidate_star_dir, 'ye[0-9]+'), '[0-9]+'))
	endif


	if keyword_set(octopus) then candidates_filename = 'octopus_candidates_pdf.idl' else if keyword_set(vartools) then candidates_filename='vartools_bls.idl' else candidates_filename = 'candidates_pdf.idl'
	if keyword_set(external_dir) then candidates_filename = 'temp_candidates_pdf.idl'
	; select the candidate to explore
	nothing  = {period:1d8, hjd0:0.0d, duration:0.02, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0}

	if file_test(star_dir + candidates_filename) eq 0 then begin
		;mprint, skipping_string, ' no candidate pdf was found!'
		;return
	endif else begin
		restore, candidate_star_dir + candidates_filename
		if keyword_set(vartools) then best_candidates = bls
	endelse


	if n_elements(best_candidates) eq 0 then best_candidates = nothing else best_candidates = [best_candidates, nothing]
;	if not keyword_set(which) then begin
;		print_struct, best_candidates
;		which = question(/number, /int, 'which candidate would you like to explore?')
;	;	print_struct, best_candidates[which]
;	endif


	if file_test(star_dir() + 'box_pdf.idl') then begin
		restore, star_dir() + 'box_pdf.idl'
		sn = max(boxes.depth/boxes.depth_uncertainty, dim=1)
		n_peaks = 20
		peaks = select_peaks(sn, n_peaks)
		which_duration = intarr(n_peaks)
		for i=0, n_peaks-1 do begin
			i_match = where(boxes[peaks[i]].depth/boxes[peaks[i]].depth_uncertainty eq sn[peaks[i]], n_match)
			if n_match eq 0 then stop
			which_duration[i] = min(i_match)
			temp = {hjd:boxes[peaks[i]].hjd, duration:boxes[peaks[i]].duration[which_duration[i]], depth:boxes[peaks[i]].depth[which_duration[i]], depth_uncertainty:boxes[peaks[i]].depth_uncertainty[which_duration[i]]}
			if n_elements(best_boxes) eq 0 then best_boxes = temp else best_boxes = [best_boxes, temp]
		endfor
		boxes_strings = rw(string(best_boxes.hjd)) +'=' + mjdtodate(best_boxes.hjd) + ', D/sigma=' + rw(string(best_boxes.depth/best_boxes.depth_uncertainty))
		whatarewelookingat = {best_candidates:best_candidates, best_boxes:best_boxes, mode:'candidate', i_candidate:0, i_box:0}
	endif else begin
		boxes_strings = 'no MarPLEs found for ' + star_dir()

	endelse



n_candidates = n_elements(whatarewelookingat.best_candidates)
n_boxes = n_elements(whatarewelookingat.best_boxes)
widget_control, xinspect_camera.candidates_list, set_value = stringify_candidate(whatarewelookingat.best_candidates)
widget_control, xinspect_camera.candidates_list, set_uvalue = 'phased'+rw(indgen(n_candidates))

widget_control, xinspect_camera.boxes_list, set_value = stringify_box(whatarewelookingat.best_boxes)
widget_control, xinspect_camera.boxes_list, set_uvalue = 'single'+rw(indgen(n_boxes))


if keyword_set(input_object) then begin
	if tag_exist(input_object, 'CANDIDATE') then begin
		i_match = where(best_candidates.period eq input_object.candidate.period, n_match)
		if n_match gt 0 then begin
			i_match = i_match[0]
			widget_control, xinspect_camera.candidates_list, set_list_select = i_match
			widget_control, xinspect_camera.boxes_list, set_list_select = -1
			whatarewelookingat.mode = 'candidate'
			whatarewelookingat.i_candidate = i_match
 			process_with_candidate, whatarewelookingat.best_candidates[whatarewelookingat.i_candidate]
		endif
	endif

endif



;candidate_list = widget_list(explorecandidate_base, value=candidate_strings, ysize=5, uvalue='phased'+rw(indgen(n_elements(candidate_strings))))
;boxes_list = widget_list(exploresingle_base, value=boxes_strings, ysize=5, uvalue='single'+rw(indgen(n_elements(candidate_strings))))

END