FUNCTION v_minus_i, t_eff
	logt = alog10(t_eff)
	v_minus_i = fltarr(n_elements(logt))
	i = where(logt lt 3.593, n)
	if n gt 0 then v_minus_i[i] = 1351.99 - 745.89*logt[i] + 103.00*logt[i]^2
	i = where(logt lt 3.45, n)
	if n gt 0 then v_minus_i[i] = 0.0/0.0
	

	

	bc_v = -2854.9
	
END