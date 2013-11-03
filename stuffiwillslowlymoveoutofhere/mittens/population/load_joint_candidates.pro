FUNCTION load_pdf_candidates, combined=combined
;+
; NAME:
;	LOAD_CANDIDATES
; PURPOSE:
;	search through MEarth directories, return candidates
; CALLING SEQUENCE:
; 	c = load_candidates(combined=combined)
; INPUTS:
;
; KEYWORD PARAMETERS:
;	/combined = search combined light curves as well as individual years 
; OUTPUTS:
;	array of {candidate} structures 
; RESTRICTIONS:
; 
; EXAMPLE:
; 	c = load_candidates(combined=combined)
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-

	new = file_search('ls*/ye*/te*/candidates_pdf.idl')
	
	ls = long(stregex(/ext, stregex(/ext, new, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, new, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, new, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(new)
	template = create_struct('LSPM', 0, 'STAR_DIR', '', 'OLD', {candidate}, 'NEW', {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0} )
	cloud = replicate(template, n)
	has_boxes = bytarr(n)
	for i=0, n-1 do begin
		s = template
		restore, new[i]
		star_dir = stregex(new[i], /ext, 'ls[0-9]+/(ye[0-9]+/te[0-9]+|combined)') +'/'
		s.new =best_candidates[0]
		has_boxes[i]= file_test(star_dir + 'box_pdf.idl')
		if file_test(star_dir + 'blind/best/candidate.idl') then begin
			restore, star_dir + 'blind/best/candidate.idl'
			s.old = candidate;copy_struct, candidate, s.old
		endif
		cloud[i] = s
		cloud[i].star_dir = star_dir
		cloud[i].lspm = ls[i]
	endfor  
	return, cloud[where(has_boxes)]
END 