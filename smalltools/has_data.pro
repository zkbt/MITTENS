FUNCTION has_data, medianed=medianed, n=n, days=days
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
	@filter_parameters
	if keyword_set(medianed) then filename = star_dir + 'medianed_lc.idl' else filename = star_dir + 'target_lc.idl'
	ft = file_test(filename)
	hasdata = ft
	if ft then begin
		if keyword_set(n) or keyword_set(days) then begin
			restore, filename
			if keyword_set(medianed) then lc = medianed_lc else lc = target_lc
			if keyword_set(n) then hasdata = hasdata AND  (n_elements(lc) ge n)
			if keyword_set(days) then begin
				nights = round(lc.hjd-mearth_timezone())
				uniq_nights = nights[uniq(nights, sort(nights))]
				hasdata = hasdata AND (n_elements(uniq_nights) gt days)
			endif
		endif
	endif
	return, hasdata
END