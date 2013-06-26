FUNCTION bin_struct_array, x, weights=weights, robust=robust
; +
; NAME:
;    
;	bin_struct_array
; 
; PURPOSE:
; 
;	Bin an array of structures into a single structure, weighting by weights, if present.
; 
; CALLING SEQUENCE:
; 
;	bin_struct_array, struct_array, weights=weights, robust=robust
; 
; INPUTS:
; 
;	x	= structure array to bin together
;	weights	= (optional) array with the same number of elements as x
; 
; KEYWORD PARAMETERS:
; 
;	/robust	= perform median binning instead of average (ignores weights)
; 
; OUTPUTS:
; 
;	a stucture with the same tags as the input, but only one element
; 
; RESTRICTIONS:
; 
;	
; 
; EXAMPLE:
; 
;	
; 
; MODIFICATION HISTORY:
;
; 	Written by Zach Berta-Thompson on 20-Nov-2010.
;
; -
	b = x[0]
	if keyword_set(weights) then w = weights else w = 1.0
	if total(w) eq 0 then w = 1.0
				
	for i=0, n_tags(b) - 1 do begin
		if size(b.(i), /type) eq 7 then continue
		b.(i) = total(/double, x.(i)*w)/total(/double, w)
	endfor
	return, b
END