PRO marples_into_candidates, start=start
	common mearth_tools
	mprint, /line
	mprint, tab_string, 'marples_into_candidates.pro is taking the MarPLES located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating periodic candidates (and an origami spectrum) from them'
	mprint, /line

;	display, /off
	verbose, /on
	interactive, /off

	f = file_search('mo*/combined/box_pdf.idl')
; ; 	run the phased search on the combined PDF timeseries

	if ~keyword_set(start) then start = 0
	mo = name2mo(f)
	for i=start*n_elements(f), n_elements(f)-1 do begin
		set_star, mo[i], /combine
		call_origami_bot
	endfor
END