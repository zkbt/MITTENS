FUNCTION bc, t_eff

	;+
	; NAME:
	;	bc
	; PURPOSE:
	;	Calculate the V-band bolometric correction for a given effective temperature.
	; EXPLANATION:
	;	Use the fits given in the appendix of Hillenbrand (1997) 
	;	to calculate BC_V as a function of T_eff. Only valid down
	;	to a spectral type of M7.
	; INPUTS:
	;	t_eff = an array of effective temperatures
	;-

	logt = alog10(t_eff)
	bc_v = fltarr(n_elements(logt))

	
	i = where(logt gt 4.100, n)
	if n gt 0 then bc_v[i] = -8.584 + 8.465*logt[i] - 1.613*logt[i]^2
	i = where(logt le 4.100, n)
	if n gt 0 then bc_v[i] = -312.902 + 161.466*logt[i] - 20.827*logt[i]^2
	i = where(logt le 3.826, n)
	if n gt 0 then bc_v[i] = -346.819 + 182.396*logt[i] -23.981*logt[i]^2
	i = where(logt le 3.571, n)
	if n gt 0 then bc_v[i] = -2854.91 + 1590.11*logt[i] -221.51*logt[i]^2
	i = where(logt le 3.45, n)
	if n gt 0 then bc_v[i] = 0.0/0.0
	
	return, bc_v	
END