PRO update_stars, remake=remake, random=random, all=all, search=search, pdf=pdf, prioritize=prioritize, fake=fake, nofold=nofold, combine=combine, old=old,year=year
;+
; NAME:
;	UPDATE_STARS
; PURPOSE:
;	loop through stars that have been loaded into MITTENS; update the analysis on them
; CALLING SEQUENCE:
; 	c = load_candidates(combined=combined)
; INPUTS:
;
; KEYWORD PARAMETERS:
;	/combined = search combined light curves as well as individual years 
; OUTPUTS:
;	array of {candidate} structures 
; RESTRICTIONS:
; EXAMPLE:
; 	c = load_candidates(combined=combined)
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
	
	; find all startel directories
	if keyword_set(all) then begin
		f = file_search('ls*/ye*/te0*/', /mark_dir) 
	endif else begin
		if keyword_set(year) then f = file_search('ls*/ye'+string(form='(I02)', year mod 2000)+'/te0*/', /mark_dir) else begin
			f = file_search('ls*/ye'+string(form='(I02)', max(possible_years) mod 2000)+'/te0*/', /mark_dir)
		endelse
	endelse
n = n_elements(f)
	
	; skip some of them
	skip_list = [	'ls3229/ye10/te04/'];, $
	
	seed = (systime(/sec) mod 1)*100000
	; if desired, start at a random place in the list of stars
	if keyword_set(random) then begin
		f = f[ (indgen(n) + uint(randomu(seed)*n)) mod n]
	endif

	if keyword_set(prioritize) then begin
		significance = fltarr(n_elements(f))
		for i=0, n_elements(f)-1 do begin
			if file_test(f[i] + 'candidates_pdf.idl') then begin
				restore, f[i] + 'candidates_pdf.idl'
				significance[i] = best_candidates[0].depth/best_candidates[0].depth_uncertainty
			endif
		endfor
		i_sort = reverse(sort(significance))
		f = f[i_sort]
	endif

	
	; extract ls, ye, and te from the directory names
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
	; loop over them, and update!
	for i=0, n-1 do begin
		if total(strmatch(skip_list, f[i])) then continue
		pipeline_2012, ls[i], old=old, year=year, fake=fake, nofold=nofold
;		update_star, ls[i], ye[i], te[i], remake=remake, search=search, pdf=pdf, fake=fake, nofold=nofold, combine=combine, all=cll
	endfor
END
