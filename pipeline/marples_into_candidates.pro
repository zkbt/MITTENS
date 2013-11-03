PRO marples_into_candidates
	common mearth_tools
	mprint, /line
	mprint, tab_string, 'marples_into_candidates.pro is taking the MarPLES located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating periodic candidates (and an origami spectrum) from them'
	mprint, /line

;	display, /off
	verbose, /on
	interactive, /off

	f = file_search('ls*/combined/box_pdf.idl')
; ; 	run the phased search on the combined PDF timeseries



	for i=0, n_elements(f)-1 do begin
		ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
		set_star, ls[i], /combine
		call_origami_bot
	endfor
END