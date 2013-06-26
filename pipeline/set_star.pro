PRO set_star, lspm, year, tel, combine=combine, random=random, n=n, days=days, fake=fake
;+
; NAME:
;	SET_STAR
; PURPOSE:
;	tell MITTENS what star to work on
; CALLING SEQUENCE:
;	set_star, lspm, year, tel, combine=combine
; INPUTS:
;	lspm = lspm number of the star to update
;	year = year, starting at the end of the monsoon (optional, defaults to current year)
;	tel = telescope (optional, defaults to tel0N with smallest N)
; KEYWORD PARAMETERS:
;	/combine (with only lspm specified)
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
	if keyword_set(random) then begin
		f = file_search('ls*/ye*/te*/', /mark_dir) 
		star_dir = f[randomu(seed)*n_elements(f)]
		lspm = long(stregex(/ext, stregex(/ext, star_dir ,'ls[0-9]+'), '[0-9]+'))
	endif else begin
		star_dir = make_star_dir(lspm, year, tel, combine=combine)   ; modify this!
	endelse
	if keyword_set(random) and keyword_set(n) and has_data(n=n,days=days) eq 0 then set_star, random=random, n=n, days=days else begin
		lspm_info = get_lspm_info(lspm)
		if keyword_set(fake) then star_dir += fake_dir
		mprint, '||||||||||||||||||||||||||||||||||||||'
		mprint, ' star set to ', star_dir
		mprint, '||||||||||||||||||||||||||||||||||||||'
	endelse
	!prompt = '|mittens{' + star_dir + '}| '

END