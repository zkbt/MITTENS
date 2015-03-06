FUNCTION mo_dir
;+
; NAME:
;	mo_dir
; PURPOSE:
;	return the "MEarth Object" directory, (e.g. "mo12345678+123456/") of the current object
; CALLING SEQUENCE:
;	mo = mo_dir()
; INPUTS:
;	none
; KEYWORD PARAMETERS:
;	none
; OUTPUTS:
;	a string containing the MEarth Object string (contains a following "/")
; RESTRICTIONS:
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
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
	common this_star
	mo_dir = stregex(star_dir, mo_prefix + mo_regex, /ext) + '/'
	return, mo_dir
END