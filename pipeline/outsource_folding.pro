PRO outsource_folding, lspm, remake=remake, year=year
;+
; NAME:
;	outsource_folding
; PURPOSE:
;	convert all MarPLES to text files, then scp them to MIT
;		(will hopefully send only those that need to be folded_
; CALLING SEQUENCE:
; 	outsource_folding
	common mearth_tools
	mprint, /line
	mprint, tab_string, 'outsource_folding.pro is shipping unprocessed MarPLES off to MIT'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'for generating periodic candidates (and an origami spectrum)'
	mprint, /line


	f = file_search('mo*/combined/box_pdf.idl')
; ; 	run the phased search on the combined PDF timeseries
	file_delete, /recur, 'marples_to_send'
	file_mkdir, 'marples_to_send'

	mo = name2mo(f)
	for i=0, n_elements(f)-1 do begin
		set_star, mo[i], /combine
		if file_test(star_dir() + 'box_pdf.idl') then begin
			
			; print the boxes to text, if necessary
			marples_filename = star_dir() + 'boxes_all_durations.txt'
			marples_filename = marples_filename[0]
			if ~is_uptodate(marples_filename, star_dir() + 'box_pdf.idl') then print_boxes_to_text
			if file_test(marples_filename) then begin
				if ~is_uptodate(marples_filename +'.bls', marples_filename) then begin
					mprint, tab_string, tab_string, doing_string, 'sending ', marples_filename, ' to MIT for phase-folding'
					file_copy, marples_filename, working_dir + 'marples_to_send/'+mo_prefix+mo[i] + '_marples.txt',/over
				endif 
			endif			
		endif
	endfor
	print, 'trying to scp the marple files over to MIT...'
	;spawn, 'scp marples_to_send/* zkbt@antares.mit.edu:/corscorpii/d1/zkbt/mearth/marples/'
	spawn, 'scp marples_to_send/* zkbt@antares.mit.edu:/akrab/d1/zkbt/mearth/marples/'
END