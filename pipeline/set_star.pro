PRO set_star, input_mo, year, tel, combined=combined, random=random, n=n, days=days, fake=fake
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
	common this_star;, star_dir, mo_info

	
	; if no year is specified, you probably want the combined directory!
	if n_elements(year) eq 0 then combined = 1

	; if there's no input MO, then pick a random one
	if n_elements(input_mo) eq 0 then random=1

	; if necessary, pick a random star
	if keyword_set(random) then begin
			mprint,tab_string,doing_string, 'picking a random star'
			combined = 1
			f = file_search(mo_prefix + '*/combined/', /mark_dir) 
			star_dir = f[randomu(seed)*n_elements(f)]
			mo = name2mo(star_dir)
			input_mo = mo
	endif

	; if a requirement has been placed on the number of data points or number of days, then check the star meets the requirement
	if keyword_set(random) and has_data(n=n,days=days) eq 0 then begin
		if n_elements(n) eq 0 then n = 0
		if n_elements(days) eq 0 then days = 0
		mprint, tab_string, tab_string, star_dir + " didn't have at least ", rw(n), " observations or ", rw(days), " unique nights"
		mprint, tab_string, tab_string, doing_string, 'trying again...'
		set_star, random=random, n=n, days=days 
	endif else begin
		
		if strmatch(input_mo, '*/*/') then begin
			; if the input string is already a directory, just go with it
			star_dir = input_mo
		endif else begin
			; set the star directory to match the input MO, (and maybe year and tel indicated)
			mo = name2mo(input_mo)
			star_dir = make_star_dir(mo, year, tel, combined=combined) 
		endelse
		; set the mo_info structure by loading the one in the directory
		if file_test(mo_dir() + 'mo_info.idl') then restore, mo_dir() + 'mo_info.idl'
	
		
		if keyword_set(fake) then star_dir += fake_dir

		mprint, 'star set to ' + star_dir +  ' = ' + currentname()
		!prompt = '|mittens{' + currentname() + '}| '
	endelse
END