FUNCTION v_minus_i, t_eff

	;+
	; NAME:
	;	v_minus_i
	; PURPOSE:
	;	Calculate the V-I_C color for a given effective temperature.
	; EXPLANATION:
	;	Use the fits given in the appendix of Hillenbrand (1997) 
	;	to calculate V-I as a function of T_eff. Only valid down
	;	to a spectral type of M7.
	; INPUTS:
	;	t_eff = an array of effective temperatures
	;-

	logt = alog10(t_eff)
	v_minus_i = fltarr(n_elements(logt))

	
	i = where(logt gt 3.993, n)
	if n gt 0 then v_minus_i[i] = 12.519 - 5.428*logt[i] + 0.572*logt[i]^2
	i = where(logt le 3.993, n)
	if n gt 0 then v_minus_i[i] = 128.334 - 63.316*logt[i] + 7.809*logt[i]^2
	i = where(logt le 3.593, n)
	if n gt 0 then v_minus_i[i] = 1351.99 - 745.89*logt[i] + 103.00*logt[i]^2
	i = where(logt le 3.45, n)
	if n gt 0 then v_minus_i[i] = 0.0/0.0
	
	return, v_minus_i	
END