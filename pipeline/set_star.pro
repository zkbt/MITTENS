PRO set_star, temp_lspm, year, tel, combined=combined, random=random, n=n, days=days, fake=fake
;+
; NAME:
;	SET_STAR
; PURPOSE:
;	tell MITTENS what star to work on
; CALLING SEQUENCE:
;	set_star, lspm, year, tel, combined=combined
; INPUTS:
;	lspm = lspm number of the star to update
;	year = year, starting at the end of the monsoon (optional, defaults to current year)
;	tel = telescope (optional, defaults to tel0N with smallest N)
; KEYWORD PARAMETERS:
;	/combined (with only lspm specified)
; OUTPUTS:
; RESTRICTIONS:
; EXAMPLE:
; 	set_star, 1186, 8, 1
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
	common mearth_tools
	common this_star, star_dir, lspm_info

	if n_elements(temp_lspm) eq 0 then random=1
	if keyword_set(random) then begin
			mprint,tab_string,doing_string, 'picking a random star'
			combined = 1
			f = file_search('ls*/combined/', /mark_dir) 
			star_dir = f[randomu(seed)*n_elements(f)]
			lspm = long(stregex(/ext, stregex(/ext, star_dir ,'ls[0-9]+'), '[0-9]+'))
			temp_lspm = star_dir
	endif
	if keyword_set(random) and has_data(n=n,days=days) eq 0 then begin
		if n_elements(n) eq 0 then n = 0
		if n_elements(days) eq 0 then days = 0
		mprint, tab_string, tab_string, star_dir + " didn't have at least ", rw(n), " observations or ", rw(days), " unique nights"
		mprint, tab_string, tab_string, doing_string, 'trying again...'
		set_star, random=random, n=n, days=days 
	endif else begin
		if typename(temp_lspm) eq 'STRING' then begin
			star_dir = temp_lspm
			lspm = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
		endif else begin
			lspm = temp_lspm
			star_dir = make_star_dir(lspm, year, tel, combined=combined)   ; modify this!
		endelse
		lspm_info = get_lspm_info(lspm)
		if keyword_set(fake) then star_dir += fake_dir
		mprint, tab_string, '||||||||||||||||||||||||||||||||||||||'
		mprint, tab_string, tab_string, ' star set to ', star_dir
		mprint, tab_string, '||||||||||||||||||||||||||||||||||||||'
		!prompt = '|mittens{' + star_dir + '}| '
	endelse
END