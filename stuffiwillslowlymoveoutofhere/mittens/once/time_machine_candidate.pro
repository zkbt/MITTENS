PRO time_machine_candidate,range, res=res, octopus=octopus, zoom=zoom
	common this_star
	cleanplot
	if keyword_set(octopus) then candidates_filename = 'octopus_candidates_pdf.idl' else if keyword_set(vartools) then candidates_filename='vartools_bls.idl' else candidates_filename = 'candidates_pdf.idl'
	restore, star_dir + candidates_filename
	if not keyword_set(which) then begin
		print_struct, best_candidates
		which = question(/number, /int, 'which candidate would you like to explore?')
	endif
	restore, star_dir + candidates_filename
	loadct, 39

	restore, star_dir + 'box_pdf.idl'
	allnights = round(boxes[uniq(round(boxes.hjd/5), sort(boxes.hjd))].hjd)
	if n_elements(range) eq 0 then range = range(allnights) > (min(allnights) + 10)
	range[1] = max(round(boxes.hjd)+1)
	i = where(allnights ge min(range) and allnights le max(range), n_nights)
	if n_nights gt 0 then begin
		nights = allnights[i]
		print, 'running time machine on ', nights
		for i=0, n_elements(nights)-1 do test = refine_candidate(best_candidates[which], /eps, asof=nights[i], res=res, zoom=zoom)
	endif else stop

END