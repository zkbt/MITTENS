FUNCTION ad, x, nan=nan
;+
; NAME:
;    
;	ad
; 
; PURPOSE:
; 
;	Return the absolute deviation from the median of an array
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
; 	Written by Zach Berta-Thompson, sometime during grad school (2008-2013).
;
;-
	return, abs(x - median(x))
END
