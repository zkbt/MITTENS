PRO combine_lightcurves, lspm
;+
; NAME:
;	COMBINE_LIGHTCURVES
; PURPOSE:
;	combine all *cleaned* MEarth light curves on a particular star together into one combined directory
; CALLING SEQUENCE:
;	combine_lightcurves, lspm
; INPUTS:
;	lspm = the star number
; KEYWORD PARAMETERS:
; OUTPUTS:
;	puts a whole ton of files in ls[????]/combined/
; RESTRICTIONS:
; EXAMPLE:
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
	lspm_dir = 'ls'+string(format='(I04)', lspm)+'/'
	f = file_search(lspm_dir + 'ye*/*/', /mark_dir)
	star_dir = lspm_dir + 'combined/'
	file_mkdir, star_dir
	for i=0, n_elements(f)-1 do begin
		star_dir = f[i]
	  	update_star, /pdf, remake=remake, long(stregex(/ex, star_dir, 'ls[0-9]+')), long(stregex(/ex, star_dir, 'ye[0-9]+')), long(stregex(/ex, star_dir, 'te[0-9]+'))
		if file_test(star_dir+ 'medianed_lc.idl') then begin
			restore, star_dir + 'medianed_lc.idl'
			restore, star_dir + 'decorrelated_lc.idl'
			restore, star_dir + 'target_lc.idl'
			restore, star_dir + 'ext_var.idl'

			restore, star_dir + 'sfit.idl'
			if n_elements(big_medianed_lc) eq 0 then big_medianed_lc = medianed_lc else big_medianed_lc = [big_medianed_lc, medianed_lc]
			if n_elements(big_decorrelated_lc) eq 0 then big_decorrelated_lc = decorrelated_lc else big_decorrelated_lc = [big_decorrelated_lc, decorrelated_lc]
			if n_elements(big_target_lc) eq 0 then big_target_lc = target_lc else big_target_lc = [big_target_lc, target_lc]
			if n_elements(big_ext_var) eq 0 then big_ext_var = ext_var else big_ext_var = [big_ext_var, ext_var]

			restore, star_dir + 'raw_target_lc.idl'
			restore, star_dir + 'raw_ext_var.idl'
			if n_elements(raw_big_target_lc) eq 0 then raw_big_target_lc = target_lc else raw_big_target_lc = [raw_big_target_lc, target_lc]
			if n_elements(raw_big_ext_var) eq 0 then raw_big_ext_var = ext_var else raw_big_ext_var = [raw_big_ext_var, ext_var]
			
		endif
		file_copy, star_dir + 'pos.txt', lspm_dir + 'combined/', /over
	endfor
	i = sort(big_medianed_lc.hjd)
	medianed_lc = big_medianed_lc[i]
	target_lc = big_target_lc[i]
	decorrelated_lc = big_decorrelated_lc[i]
	ext_var = big_ext_var[i]

	star_dir = lspm_dir + 'combined/'
	file_mkdir, star_dir
	save, filename=star_dir + 'medianed_lc.idl', medianed_lc
	save, filename=star_dir + 'decorrelated_lc.idl', decorrelated_lc
	save, filename=star_dir + 'target_lc.idl', target_lc
	save, filename=star_dir + 'ext_var.idl', ext_var
	save, filename=star_dir + 'sfit.idl', sfit

	superfit = {lc:target_lc, decorrelation:target_lc.flux - decorrelated_lc.flux, variability:decorrelated_lc.flux - medianed_lc.flux, cleaned:medianed_lc.flux}
	save, filename=star_dir + 'superfit.idl'
		

	i = sort(raw_big_target_lc.hjd)
	ext_var = raw_big_ext_var[i]
	save, filename=star_dir + 'raw_ext_var.idl', ext_var
	target_lc = raw_big_target_lc[i]
	save, filename=star_dir + 'raw_target_lc.idl', target_lc


END