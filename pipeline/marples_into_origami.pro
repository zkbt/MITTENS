PRO marples_into_origami, desired_mo, start=start
	common mearth_tools
	
	if keyword_set(desired_mo) then begin
		;pass the MO through name2mo to make sure it becomes a valid MEarth Object
		desired_mo = name2mo(desired_mo)
		for i=0, n_elements(desired_mo)-1 do begin
		  set_star, desired_mo[i]
		  call_origami_bot
		endfor 
		return
	endif
	mprint, /line
	mprint, tab_string, 'marples_into_origami.pro is taking the MarPLES located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating periodic origami spectra from them'
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