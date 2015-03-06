FUNCTION sign, x
	s = intarr(n_elements(x))
	i_pos = where(x gt 0, n_pos)
	if n_pos gt 0 then s[i_pos] = 1
	i_neg = where(x lt 0, n_neg)
	if n_neg gt 0 then s[i_neg] = -1
	return, s
END