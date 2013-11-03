PRO fits_into_lightcurves, desired_lspm, remake=remake, all=all, old=old
;+
; NAME:
;	fits_into_lightcurves
; PURPOSE:
;	load one (or many) MEarth stars into MITTENS format
;
; CALLING SEQUENCE:
;	load_lightcurve, desired_lspm, remake=remake, all=all
;
; INPUTS:
;	desired_lspm = the lspm number of the star in interest (optional, defaults to /all if absent)
;
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
;	/all = load data for all MEarth stars (tries to ignore stars that are up-to-date)
;	/old = load data not only from the current year, but also from past years
;
; OUTPUTS:
;	writes lots of files to the $MITTENS_DATA directory, seperated into useful directories
;
; RESTRICTIONS:
; EXAMPLES:
;	fits_into_lightcurves, /all	; (load all FITS light curves, from all seasons and telescopes, into @MITTENS_DATA)
;	fits_into_lightcurves, 1186 ; (loads a specific star, identified by LSPM number)
;
; MODIFICATION HISTORY:
;	Written by Zachory K. Berta-Thompson, as part of the
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime while he was in grad school (2008-2013).
;-

	common mearth_tools
	mprint, 'fits_into_lightcurves.PRO is loading lightcurve(s) into ' + working_dir
	; figure out whether loading just one or all of the stars
	if ~keyword_set(desired_lspm) then all = 1
	if keyword_set(all) then begin
		lspm = '*' 
		search_string = 'lspm*'
	endif else begin
		lspm = desired_lspm + indgen(5)-2
		search_string = 'lspm'+strcompress(/remo, lspm)
	endelse

	; loop over the possible years
	if keyword_set(old) then k_start = 0 else k_start = n_elements(possible_years)-1
	for k=k_start, n_elements(possible_years)-1 do begin
		year = possible_years[k]	
		tel_string = 'tel0*'
		dir = reduced_dir[k] + tel_string + '/master/'
		if keyword_set(desired_lspm) then begin
			f_jmi = file_search('ls'+string(form='(I04)', desired_lspm) + '/ye'+string(form='(I02)', year mod 100) + '/te*/jmi_file_prefix.idl')
			if f_jmi[0] ne '' then for i=0, n_elements(f_jmi)-1 do begin
				restore, f_jmi[i]
				if n_elements(jmi_this_year) eq 0 then jmi_this_year = jmi_file_prefix + fits_suffix else jmi_this_year =[jmi_this_year, jmi_file_prefix + fits_suffix]
			endfor
		endif else jmi_this_year = file_search(dir + search_string + fits_suffix)

		exclude_list = ['lspm1335_2010_']
		
		; loop through fields available this year
		for i=0, n_elements(jmi_this_year)-1 do begin
			; figure out what the MITTEN filename of the first M dwarf in the field would be called
			tel = long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'tel[0-9]+'), '[0-9]+'))
			lspm =  long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'lspm[0-9]+'), '[0-9]+'))
			mitten_filename = make_star_dir(lspm, year, tel)+'raw_ext_var.idl'
			; if it's not up-to-date, load the light curves
			if is_uptodate(mitten_filename, jmi_this_year[i]) eq 0 or keyword_set(remake) and total(strmatch(jmi_this_year[i], '*' + exclude_list+'*')) eq 0 then begin	
;				if question(jmi_this_year[i],/int) then stop
				get_jonathans_lightcurves, jmi_this_year[i], remake=remake
			endif else mprint, skipping_string, ' raw lightcurves in ', jmi_this_year[i], ' are up to date! '
		endfor
	endfor
END