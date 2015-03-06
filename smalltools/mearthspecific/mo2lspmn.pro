FUNCTION mo2lspmn, input_mo
	common mearth_tools
	; strip off any extra characters from MO
	mo = name2mo(input_mo)
	lspmn = lonarr(n_elements(mo))
	
	for i=0, n_elements(mo)-1 do begin
		if mo_valid(mo[i]) then begin
			i_match = where(mo_ensemble.mo eq mo[i], n_match)
			if n_match eq 0 then begin
				mprint, tab_string, error_string, 'no matching MO was found for ', mo[i]
				lspmn[i] = 0
			endif
			if n_match gt 1 then begin
				mprint, tab_string, error_string, "too many matching MO's were found for", mo[i]
				lspmn[i] = 0
			endif
			if n_match eq 1 then begin
				lspmn[i] = mo_ensemble[i_match].lspmn
				mprint, tab_string, mo[i], ' --> ls', string(format='(I04)', lspmn[i])
			endif		
		endif else mprint, error_string, mo, ' is not a valid MEarth Object string'
	endfor
	if n_elements(lspmn) eq 1 then lspmn = lspmn[0]
	return, lspmn
END