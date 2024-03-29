FUNCTION has_data, n=n, days=days
;+
; NAME:
;	HAS_DATA
; PURPOSE:
;	fast way to tell whether or not a star has data
; CALLING SEQUENCE:
;	h = has_data()
; INPUTS:
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	/medianed = test whether or not there's a cleaned light curve (defaults to caring about raw, binned light curve)
; OUTPUTS:
;	0 or 1
; RESTRICTIONS:
; EXAMPLE:
; 	if has_data() then [look for planets!]
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-
	
	common this_star
	common mearth_tools
	@filter_parameters
	filename = star_dir + 'ext_var.idl'

	ft = file_test(filename)
	hasdata = ft
	if ft then begin
		if keyword_set(n) or keyword_set(days) then begin
			restore, filename
			lc = ext_var
			if keyword_set(n) then hasdata = hasdata AND  (n_elements(lc) ge n)
			mprint, tab_string, tab_string, tab_string, star_dir + ' has ' + rw(n_elements(lc)) + ' observations'
			if keyword_set(days) then begin
				nights = round(lc.mjd_obs-mearth_timezone())
				uniq_nights = nights[uniq(nights, sort(nights))]
				hasdata = hasdata AND (n_elements(uniq_nights) ge days)
				mprint, tab_string, tab_string, tab_string, star_dir + ' has ' + rw(n_elements(uniq_nights)) + ' unique nights'

			endif
		endif
	endif
	return, hasdata
END