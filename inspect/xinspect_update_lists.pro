FUNCTION stringify_candidate, candidate
	str = rw('P='+string(candidate.period, form='(F12.6)')) + ' days, ' + rw(string(candidate.depth/candidate.depth_uncertainty, form='(F6.2)')) + ' sigma'
	i = where(candidate.period gt 1000, n)
	if n gt 0 then str[i] = '(nothing)'
	return, str
END

FUNCTION stringify_box, box
	if tag_exist(box, 'HJD') then str =  rw(string(box.hjd)) +'=' + mjdtodate(box.hjd) + ', ' + rw('D='+string(box.depth, form='(F12.4)')) + ' mag., ' + rw(string(box.depth/box.depth_uncertainty, form='(F6.2)')) + ' sigma' else str = '(nothing)'
;	i = where(box.period gt 1000, n)
;	if n gt 0 then str[i] = '(nothing)'
	return, str
END


PRO xinspect_update_lists, input_object=input_object

	; load common blocks
	common xinspect_common
	common this_star
	common mearth_tools

	; =========================
	;    load the candidates!
	; =========================


	; set the candidate directory to the current star directory and the filename to the default
	candidate_star_dir = star_dir
	candidates_filename = typical_candidate_filename 

	; figure out if this is the combination of multiple years/telescopes (by default it should be)
	if strmatch(candidate_star_dir, '*combined*') gt 0 then begin
		combined=1
		if strmatch(candidate_star_dir, '*ye*') then year_of_combination = long(stregex(/extract, stregex(/extrac, candidate_star_dir, 'ye[0-9]+'), '[0-9]+'))
	endif
	
	; select the candidate to explore
	nothing  = {period:1d8, hjd0:0.0d, duration:0.02, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0, inflation_for_bad_duration:1.0}

	; restore the candidate file
	if file_test(star_dir + candidates_filename) eq 0 then begin

	endif else begin
		restore, candidate_star_dir + candidates_filename
	endelse

	; make sure the candidate structure contains at least "nothing"
	if n_elements(best_candidates) eq 0 then best_candidates = nothing else best_candidates = [best_candidates, nothing]

	; load the boxes for this star
	if file_test(star_dir() + 'box_pdf.idl') then begin

		; find the highest SNR duration at each possible box epoch
		restore, star_dir() + 'box_pdf.idl'
		temp = {hjd:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0}
		n_durations = n_elements(boxes[0].duration)
		best_boxes = replicate(temp, n_durations*n_elements(boxes))
		best_boxes.hjd = reform(ones(n_durations)#boxes.hjd, n_elements(boxes.duration))
		best_boxes.duration = reform(boxes.duration, n_elements(boxes.duration))
		best_boxes.depth = reform(boxes.depth, n_elements(boxes.duration))
		best_boxes.depth_uncertainty = reform(boxes.depth_uncertainty, n_elements(boxes.duration))
		
		best_boxes = best_boxes[reverse(sort(best_boxes.depth/best_boxes.depth_uncertainty))]
		
;		sn = max(boxes.depth/boxes.depth_uncertainty, dim=1)
;		n_peaks = n_elements(sn)
;		peaks = reverse(sort(sn));select_peaks(sn, n_peaks)
;		which_duration = intarr(n_peaks)
;		for i=0, n_peaks-1 do begin
;			for j=0, n_elements(boxes[0].duration)-1
;				i_match = where(boxes[peaks[i]].depth/boxes[peaks[i]].depth_uncertainty eq sn[peaks[i]], n_match)
;				if n_match eq 0 then stop
;				which_duration[i] = min(i_match)
;				temp = {hjd:boxes[peaks[i]].hjd, duration:boxes[peaks[i]].duration[which_duration[i]], depth:boxes[peaks[i]].depth[which_duration[i]], depth_uncertainty:boxes[peaks[i]].depth_uncertainty[which_duration[i]]}
;				if n_elements(best_boxes) eq 0 then best_boxes = temp else best_boxes = [best_boxes, temp]
;			endfor
;		endfor

	endif else best_boxes = nothing

	whatarewelookingat = {best_candidates:best_candidates, best_boxes:best_boxes, mode:'candidate', i_candidate:0, i_box:0}



	; the number of items in the boxes and candidates lists
	n_candidates = n_elements(whatarewelookingat.best_candidates)
	n_boxes = n_elements(whatarewelookingat.best_boxes)

	; update the items in the selectable list of candidates
	widget_control, xinspect_camera.candidates_list, set_value = stringify_candidate(whatarewelookingat.best_candidates)
	widget_control, xinspect_camera.candidates_list, set_uvalue = 'phased'+rw(indgen(n_candidates))

	; update the items in the selectable list of boxes
	widget_control, xinspect_camera.boxes_list, set_value = stringify_box(whatarewelookingat.best_boxes)
	widget_control, xinspect_camera.boxes_list, set_uvalue = 'single'+rw(indgen(n_boxes))


	; if an object was entered as an input (e.g. something that was clicked on in the plot window), select that object 
	if keyword_set(input_object) then begin
		
		; was the object a candidate?
		if tag_exist(input_object, 'CANDIDATE') then begin
			; find the matching object in the selectable list
			i_match = where(best_candidates.period eq input_object.candidate.period, n_match)
			if n_match gt 0 then begin
				i_match = i_match[0]
				; make sure that candidate is selected in the list, and unselect everything from the boxes list
				widget_control, xinspect_camera.candidates_list, set_list_select = i_match
				widget_control, xinspect_camera.boxes_list, set_list_select = -1
				whatarewelookingat.mode = 'candidate'
				whatarewelookingat.i_candidate = i_match
				process_with_candidate, whatarewelookingat.best_candidates[whatarewelookingat.i_candidate]
			endif else stop
		endif
		if tag_exist(input_object, 'MARPLE') then begin
			i_match = where(whatarewelookingat.best_boxes.hjd eq input_object.marple.hjd and whatarewelookingat.best_boxes.duration eq input_object.marple.duration, n_match)
			if n_match gt 0 then begin
				i_match = i_match[0]
				widget_control, xinspect_camera.candidates_list, set_list_select = -1
				widget_control, xinspect_camera.boxes_list, set_list_select = i_match
				whatarewelookingat.mode = 'marple'
				whatarewelookingat.i_box = i_match			
				process_with_candidate, whatarewelookingat.best_boxes[whatarewelookingat.i_box]
			endif else stop
		endif
		if tag_exist(input_object, 'STAR') then begin
			if best_candidates[0].period lt 1e3 then begin
				i_match = 0
				widget_control, xinspect_camera.candidates_list, set_list_select = i_match
				widget_control, xinspect_camera.boxes_list, set_list_select = -1
				whatarewelookingat.mode = 'candidate'
				whatarewelookingat.i_candidate = i_match
				process_with_candidate, whatarewelookingat.best_candidates[whatarewelookingat.i_candidate]
			endif else if tag_exist(best_boxes[0], 'HJD') then begin
				i_match = 0
				widget_control, xinspect_camera.candidates_list, set_list_select = -1
				widget_control, xinspect_camera.boxes_list, set_list_select = i_match
				whatarewelookingat.mode = 'marple'
				whatarewelookingat.i_box = i_match			
				process_with_candidate, whatarewelookingat.best_boxes[whatarewelookingat.i_box]
			endif
		endif
	endif



;candidate_list = widget_list(explorecandidate_base, value=candidate_strings, ysize=5, uvalue='phased'+rw(indgen(n_elements(candidate_strings))))
;boxes_list = widget_list(exploresingle_base, value=boxes_strings, ysize=5, uvalue='single'+rw(indgen(n_elements(candidate_strings))))

END