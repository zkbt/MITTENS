FUNCTION blackbody, T, nu=nu, lambda=lambda, micron=micron, cm=cm, nm=nm, angstrom=angstrom
;+
; NAME:
;    
;	blackbody
; 
; PURPOSE:
; 
;	return a blackbody function, in either wavelength or frequency units
; 
; CALLING SEQUENCE:
; 
;	absolute_deviations = ad(array)
; 
; INPUTS:
;	
;	x = array, of any dimensions
; 
; KEYWORD PARAMETERS:
; 
;	/nan = mysteriously, doesn't do anything
; 
; OUTPUTS:
; 
;	(none)
; 
; RESTRICTIONS:
; 
;	probably lots
;
; EXAMPLE:
; 
;	x = randomn(seed, 100) + 42
;	absolute_deviations = ad(x)
; 
; MODIFICATION HISTORY:
;
; 	written by Zach Berta-Thompson, sometime before 2013.
;
;-
	if keyword_set(nu) and keyword_set(lambda) then print, ' !(*&#%@! make up your mind! (blackbody.pro)'

	c = 2.99792458d10		; cm/s
	h = 6.6260755d-27		; erg s
	k_b = 1.38d-16		; ergs/K

	
	if keyword_set(nu) then begin
		if keyword_set(hz) then factor=1.0d
		if keyword_set(ghz) then factor=1.0d9
		hv = h*nu
		kt = k_b*T
		RETURN, 2.0*h*nu/c^2*nu/(exp(hv/kt)-1.0d)*nu
	endif
	
	
	if keyword_set(lambda) then begin
		if keyword_set(cm) then factor = 1.0d
		if keyword_set(micron) then factor = 1d4
		if keyword_set(nm) then factor = 1d7
		if keyword_set(angstrom) then factor = 1d8
		n_units = total([keyword_set(cm), keyword_set(micron), keyword_set(nm), keyword_set(angstrom)])
		if n_units eq 0 then print, "&*!%^&! you didn't specify any units on the wavelengths! (blackbody.pro)"
		if n_units gt 1 then print, "&*!%^&! you specified too many units on the wavelengths! (blackbody.pro)"
		nu = c/(lambda/factor)
		hv = h*nu
		kt = k_b*T
		RETURN, 2.0*h*nu/c^2/lambda*nu/(exp(hv/kt)-1.0d)*nu/lambda*c
	endif
	print, ' !*&@#%(! please specify frequency/wavelength (blackbody.pro)'
	
END
