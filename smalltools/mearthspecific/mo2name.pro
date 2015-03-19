FUNCTION mo2name, mo
	common mearth_tools
	names = name2mo(mo)
	
	for i=0, n_elements(mo)-1 do begin
		i_match = where(mo_ensemble.mo eq name2mo(mo[i]), n_match)
		if n_match eq 0 then continue
		if n_match gt 1 then i_match = i_match[0]
		
		if mo_ensemble[i_match].bestname ne '' then begin
			names[i] = mo_ensemble[i_match].bestname
			continue
		endif

		if mo_ensemble[i_match].lspmn ne 0 then begin
			names[i] =string(form='(I04)', mo_ensemble[i_match].lspmn)
			continue
		endif

		if mo_ensemble[i_match].lhs ne '' then begin
			names[i] = 'LHS' + rw( mo_ensemble[i_match].lhs)
			continue
		endif

		if mo_ensemble[i_match].nltt gt 0 and  mo_ensemble[i_match].nltt lt 100000l  then begin
			names[i] = 'NLTT' + rw( mo_ensemble[i_match].NLTT)
			continue
		endif
		names[i] = 'MO' + mo[i]
	endfor
	if n_elements(names) eq 1 then names = names[0]

	return, names

END