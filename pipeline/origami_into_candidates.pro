PRO origami_into_candidates, desired_mo, start=start
	common mearth_tools
	
	if keyword_set(desired_mo) then begin
		;pass the MO through name2mo to make sure it becomes a valid MEarth Object
		desired_mo = name2mo(desired_mo)
		for i=0, n_elements(desired_mo)-1 do begin
		  set_star, desired_mo[i]
		  extract_candidates_from_origami
		endfor 
		return
	endif
	mprint, /line
	mprint, tab_string, 'origami_into_candidates.pro is taking the origami spectra located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating periodic candidates from them'
	mprint, /line

	f = file_search('mo*/combined/boxes_all_durations.txt.bls')
	if ~keyword_set(start) then start = 0
	mo = name2mo(f)
	for i=start*n_elements(f), n_elements(f)-1 do begin
		set_star, mo[i], /combine
		extract_candidates_from_origami
	endfor
END