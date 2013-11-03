PRO load_lightcurve, desired_lspm, remake=remake, all=all, old=old

; +
; NAME:
;    
;	load_lightcurves
; 
; PURPOSE:
; 
;	Search Jonathan's light MEarth light curves for new entrys, and add them to "stars/tel??lspm????/"
; 
; CALLING SEQUENCE:
; 
;	load_lightcurves, [tel, lspm], /remake
; 
; INPUTS:
; 
;	tel, lspm	=	if specified, then just load that one star
; 
; KEYWORD PARAMETERS:
; 
;	/remake	=	reload the light curve, even if an up-to-date file exists (otherwise don't!)
; 
; OUTPUTS:
; 
;	Saves the following files:
;
;		stars/tel??lspm????/raw_target_lc.idl	=	target light curve before clipping + squashing
;		stars/tel??lspm????/target_lc.idl		=	preened target light curve
;		stars/tel??lspm????/raw_ext_var.idl	=	raw external variables (weather, image params, etc...)
;		stars/tel??lspm????/ext_var.idl		=	preened external variables
;		stars/tel??lspm????/jmi_file_prefix.idl	=	string containing the prefix to locate Jonathan's file
;												(useful for multiple star fields)
;		stars/tel??lspm????/good_mjd.idl		=	time stamps of the good points
;		stars/tel??lspm????/bad_mjd.idl		=	time stamps of the bad points
;		stars/tel??lspm????/comparisons_lc.idl	=	light curves of the other stars in the field
;		stars/tel??lspm????/field_info.idl		=	static information about the field
; 
; RESTRICTIONS:
; 
;	
; 
; EXAMPLE:
; 
;	
; 
; MODIFICATION HISTORY:
;
; 	Written by ZKB on 20-Nov-2010.
;
; -

	common mearth_tools

	; if called without telescopes, assume all telescopes
; 	if n_elements(tel) eq 0 then for i=1, 8 do load_lightcurves, i, remake=remake, old=old else begin
; 	print
; 	printl
; 	print, ' loading light curves on telescope ', strcompress(/remo, tel)
; 	printl	
; 	print
		if keyword_set(all) then lspm = '*' else	lspm = desired_lspm + indgen(5)-2
		; if called with lspm number, only search for that number (doesn't include secondary targets in fields)
		if n_elements(lspm) gt 0 and not keyword_set(all) then search_string =  'lspm'+strcompress(/remo, lspm) else search_string = 'lspm*'


	if keyword_set(old) then begin
		reduced_dir = '/data/mearth2/2008-2010-iz/reduced/'
		year = 2008
	endif else begin
		year = 2010
	endelse

		; get filenames for all lspm's
		tel_string = 'tel0*' ;+ string(tel, format='(I1)')
		dir = reduced_dir + tel_string + '/master/'
		result = file_search(dir + search_string +'_lc.fits')

		; loop through fields
		for i=0, n_elements(result)-1 do begin
			tel = long(stregex(/ex, stregex(/ex, result[i], 'tel[0-9]+'), '[0-9]+'))
			lspm =  long(stregex(/ex, stregex(/ex, result[i], 'lspm[0-9]+'), '[0-9]+'))+ indgen(5)-2
			mylc = file_info(make_star_dir(lspm, year, tel)+'target_lc.idl')
			jlc = file_info(result[i])
			if (max(mylc.mtime) lt jlc.mtime or keyword_set(remake)) then get_jonathans_lightcurves, result[i], remake=remake, old=old
		endfor
	;endelse

END