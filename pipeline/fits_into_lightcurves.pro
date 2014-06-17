PRO fits_into_lightcurves, desired_mo, remake=remake, all=all, old=old, k_start=k_start
;+
; NAME:
;	fits_into_lightcurves
; PURPOSE:
;	load one (or many) MEarth stars into MITTENS format
;
; CALLING SEQUENCE:
;	load_lightcurve, desired_mo, remake=remake, all=all
;
; INPUTS:
;	desired_mo = the MEarth Object you'd like of the star in interest (optional, defaults to /all if absent)
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


	if keyword_set(desired_mo) then begin
		;pass the MO through name2mo to make sure it becomes a valid MEarth Object
		desired_mo = name2mo(desired_mo)
	endif else begin
		; run through all MO's, if none are set
		all = 1
	endelse

	if keyword_set(all) then begin
		; include all of Jonathan's light curves
		mo = '*' 
		search_string = '*'
	endif else begin
		; try to pull out just the files that you need (tricky for the few fields that are unlabeled multiples
		
		; if the object is in the northern hemisphere
		if hemisphere(desired_mo) eq 'N' then begin
			desired_lspm = mo2lspm(desired_mo)
			lspm = desired_lspm + indgen(5)-2
			search_string = '*lspm'+strcompress(/remo, lspm)
		endif
	
		if hemisphere(desired_mo) eq 'S' then begin
			search_string = '*' + mo_prefix + '*' 
		endif

	endelse

	; loop over the possible years
	if ~keyword_set(k_start) then begin
		if keyword_set(old) then k_start = 0 else k_start = min(where(possible_years eq max(possible_years))) 
	endif
	for k=k_start, n_elements(possible_years)-1 do begin
		; different years may have different directories; loop through them
		year = possible_years[k]	
		; pull out the telescope string
		tel_string = 'tel*'
			
		; include the 
		dir = reduced_dir[k] + tel_string + '/master/'
		if keyword_set(desired_mo) then begin
			f_jmi = file_search(mo_prefix+desired_mo + '/ye'+string(form='(I02)', year mod 100) + '/te*/jmi_file_prefix.idl')
			if f_jmi[0] ne '' then for i=0, n_elements(f_jmi)-1 do begin
				restore, f_jmi[i]
				if n_elements(jmi_this_year) eq 0 then jmi_this_year = jmi_file_prefix + fits_suffix else jmi_this_year =[jmi_this_year, jmi_file_prefix + fits_suffix]
			endfor
		endif else begin
			jmi_this_year = file_search(dir + search_string + fits_suffix)
			if jmi_this_year[0] eq '' then jmi_this_year = file_search(dir + search_string + '_lc.fits')
		endelse
		
		exclude_list = ['lspm1335_2010_', 'hat', 'xo', 'sa', 'k', 'hd', 'hip', 'gj', 'tvlm']
		for e = 0, n_elements(exclude_list)-1 do begin
			i_exclude = where(strmatch(jmi_this_year, '*' + exclude_list[e]+'*'), n_exclude, complement=i_include)
			if i_include[0] eq -1 then stop
			jmi_this_year = jmi_this_year[i_include]
		endfor

		; WHEN ADDING SOUthERN HEMISPHERE, I BROKE THE ABILITY TO UPDATE INDIVIDUAL FILES WITHOUT OPENING THE DAILY FITS FILES
		; loop through fields available this year
		for i=0, n_elements(jmi_this_year)-1 do begin
			; figure out what the MITTEN filename of the first M dwarf in the field would be called
			tel = long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'tel[0-9]+'), '[0-9]+'))
			lspm =  long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'lspm[0-9]+'), '[0-9]+'))
			if lspm gt 0 then mo = name2mo(lspm) else mo = name2mo(jmi_this_year[i])
			if mo eq '' then continue
			mitten_filename = make_star_dir(mo, year, tel)+'raw_ext_var.idl'
			; if it's not up-to-date, load the light curves
			if is_uptodate(mitten_filename, jmi_this_year[i]) eq 0 or keyword_set(remake) then begin	
;				if question(jmi_this_year[i],/int) then stop
				get_jonathans_lightcurves, jmi_this_year[i], remake=remake
			endif else mprint, skipping_string, ' raw lightcurves in ', jmi_this_year[i], ' are up to date! '
		endfor
	endfor
END