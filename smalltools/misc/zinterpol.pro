FUNCTION zinterpol, v, x, u, lsquadratic=lsquadratic, quadratic=quadratic, spline=spline
;+
; NAME:
;	ZINTERPOL
; PURPOSE:
;	like INTERPOL, but force to zero outside range
; CALLING SEQUENCE:
; 	z = zinterpol(v, x, u)
; INPUTS:
;	
; KEYWORD PARAMETERS:
;	
; OUTPUTS:
;	
; RESTRICTIONS:
; 	
; EXAMPLE:
; 	
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-


	; use interpol, but force to zero outside range
;	if keyword_set(reverse) then return, interpol(reverse([0,0,v,0,0]), reverse([(min(u) < min(x)) - abs(x[1]-x[0]), min(u) > min(x), x, max(x) < max(u), max(x) > max(u) + abs(x[n_elements(x)-1]-x[n_elements(x)-2])]), reverse(u))
	return, interpol([0,0,v,0,0], [(min(u) < min(x)) - abs(x[1]-x[0]), min(u) > min(x), x, max(x) < max(u), max(x) > max(u) + abs(x[n_elements(x)-1]-x[n_elements(x)-2])], u)
END