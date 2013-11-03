PRO predict_events,i, eps=eps, res=res, zoom=zoom, octopus=octopus, shorten=shorten, external_dir
	common mearth_tools
	common this_star
	file_mkdir, star_dir + '/plots'
	file_mkdir, star_dir + '/predictions'
	cleanplot
	if ~keyword_set(eps) then xplot, ysize=1000
;	restore, star_dir + 'spectrum_pdf.idl'
; 	if keyword_set(octopus) then candidates_filename = 'octopus_candidates_pdf.idl' else if keyword_set(vartools) then candidates_filename='vartools_bls.idl' else candidates_filename = 'candidates_pdf.idl'
; 
; 	if keyword_set(external_dir) then begin
; 	;	file_copy, star_dir + 'candidates_pdf.idl',  star_dir + 'backup_candidates_pdf.idl'
; 		if keyword_set(octopus) then file_copy, external_dir + 'octopus_candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over else file_copy, external_dir + 'candidates_pdf.idl', star_dir + 'temp_candidates_pdf.idl', /over
; 		candidates_filename = 'temp_candidates_pdf.idl'
; 	endif

	candidates_filename = typical_candidate_filename

	restore, star_dir + candidates_filename
	loadct, 39

	n =10
	if keyword_set(shorten) then best_candidates.duration *=shorten
	if keyword_set(i) then begin
			test = refine_candidate(best_candidates[i], eps=eps, res=res, zoom=zoom)
	endif else begin
		for i=0, n-1 do begin
			test = refine_candidate(best_candidates[i], eps=eps, res=res, zoom=zoom)
		endfor
	endelse
END