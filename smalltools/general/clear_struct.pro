PRO clear_struct, st
;+
; NAME:
;	clear_struct
; PURPOSE:
;	zeroes out all elements in all tags of an IDL structure (including strings)
; CALLING SEQUENCE:
;	clear_struct, thisisthenameofastructure
; INPUTS:
;	the structure whose elements you want to erase
; KEYWORD PARAMETERS:
;	none
; OUTPUTS:
;	none; it just messes with the input structure
; RESTRICTIONS:
; EXAMPLE:
; MODIFICATION HISTORY:
; 	Written by ZKBT (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2014.
;-
	for t=0, n_tags(st)-1 do begin
		case typename(st.(t)) of
			'STRING': st.(t) = ''
			'FLOAT': st.(t) = 0.0
			'DOUBLE': st.(t) = 0.0
			'LONG': st.(t) = 0
			'INT': st.(t) = 0.0
		endcase
	endfor
END