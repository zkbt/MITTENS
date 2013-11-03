FUNCTION load_pdf_candidates, combined=combined,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, unknown=unknown, keep=keep, octopus=octopus, vartools=vartools
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
	skiplist = [1186, 3229, 1803, 3512]
	if keyword_set(octopus) then filename = 'octopus_candidates_pdf.idl' else if keyword_set(vartools) then filename='vartools_bls.idl' else filename = 'candidates_pdf.idl'
	new = subset_of_stars(filename,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, combined=combined) + filename

	if keyword_set(unknown) then begin
		ls =  long(stregex(/ext, stregex(/ext, new, 'ls[0-9]+'), '[0-9]+'))
		i_unknown = where(ls ne 1186 and ls ne 3512 and ls ne 3229 and ls ne 1803, n)
		if n gt 0 then new = new[i_unknown] else stop
	endif
	ls = long(stregex(/ext, stregex(/ext, new, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, new, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, new, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(new)
	template = create_struct('LSPM', 0, 'STAR_DIR', '', {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0, ignore:0B, known:0B, variability:0B, stats:{boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}} )
	cloud = replicate(template, n)
	has_boxes = bytarr(n)
	for i=0, n-1 do begin
		s = template
		restore, new[i]
		if keyword_set(vartools) then best_candidates = bls
		star_dir = stregex(new[i], /ext, 'ls[0-9]+/(ye[0-9]+|combined)/((te[0-9]+|combined)/)?');stregex(new[i], /ext, 'ls[0-9]+/(ye[0-9]+/te[0-9]+|combined)') +'/'
		copy_struct, best_candidates[0], s
		has_boxes[i]= file_test(star_dir + 'box_pdf.idl')
		
		if file_test(star_dir + 'comments.log') then begin
			comments = ''
			openr, lun, /get_lun, star_dir + 'comments.log'
			while eof(lun) eq 0 do begin
				readf, lun, comments
				if strmatch(comments, '*IGNORE*', /fold_case) then s.ignore = 1
				if strmatch(comments, '*VARIAB*', /fold_case) then s.variability = 1
				if strmatch(comments, '*KNOWN*', /fold_case) then s.known = 1
			endwhile
			close, lun
			free_lun, lun
			
		endif
		cloud[i] = s
		cloud[i].star_dir = star_dir
		cloud[i].lspm = ls[i]
		if file_test(star_dir + 'box_pdf.idl') then begin
			if keyword_set(octopus) then restore, star_dir + 'octopus_stat_summary.idl' else restore, star_dir + 'stat_summary.idl'
			cloud[i].stats = stats
		endif
		
	endfor  
	return, cloud[where(has_boxes)]
END 