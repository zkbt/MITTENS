FUNCTION name2mo, input
;+
; NAME:
;	name2mo
; PURPOSE:
;	takes an input name, and converts it to a 2MASS-style MEarth Object identifier
; CALLING SEQUENCE:
;	name2mo, name/number/MO (either as scalar or as array)
; INPUTS:
;	none
; KEYWORD PARAMETERS:
;	none
; OUTPUTS:
;	a string (or array of strings) containing MEarth Object identifier(s)
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
	common mearth_tools

	; if the input is an array, then loop over all its elements
	mo = strarr(n_elements(input))
	for i=0, n_elements(input)-1 do begin
		this = input[i]
		; if it's a string, check to see if it's already in 2MASS form (8+7)
		if typename(input) eq 'STRING' then begin
			attempted_mo = strip_twomass(this)
			if strlen(attempted_mo) eq 16 then begin 
				mo[i] = attempted_mo
				;mprint, tab_string, 'interpreting ', attempted_mo, ' as a valid 2MASS MEarth identifier'
			endif else begin
				imatch = where(strmatch(mo_ensemble.bestname, this, /fold_case), nmatch)
				if nmatch eq 1 then begin
				  mo[i] = mo_ensemble[imatch].mo
				endif else begin
				  mprint, tab_string, 'name2mo.pro could not find a unique match for ', this
				endelse
			endelse
		endif
		if typename(this) eq 'INT' or typename(this) eq 'LONG' or typename(this) eq 'FLOAT' or typename(this) eq 'DOUBLE' then begin
			;mprint, tab_string, 'interpreting ', rw(this), ' as an old-school LSPM number'
			i_match = where(mo_ensemble.lspmn eq long(this), n_match)
			if n_match eq 0 then begin
				mprint, tab_string, error_string, 'but no matching MEarth Objects were found!'
			endif else begin
				if n_match gt 1 then begin 
					mprint, tab_string, error_string, 'multiple matching MEarth Objects were found, using the first one!'
					mprint, tab_string, tab_string, mo_ensemble[i_match].mo
					mo[i] = mo_ensemble[i_match[0]].mo
				endif else begin
					mo[i] = mo_ensemble[i_match].mo
					;mprint, tab_string, tab_string, this, ' --> ', mo[i]
				endelse
			endelse
		endif
	endfor

	; if only a single element was input to function, spit out a scaler instead of array (prevents bugs)
	if n_elements(mo) eq 1 then mo = mo[0]
	return, mo

END