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
		;desired_mo = progress[reverse(sort(progress.lightcurves))].mo
		desired_mo = mo_ensemble[sort(mo_ensemble.dec)].mo
	endelse

	; loop over the desired mo's
	for i=0, n_elements(desired_mo)-1 do begin
	   stillneeded=1
	   if strmatch(desired_mo[i], '*\?*') then continue
	   set_star, desired_mo[i]
	   files = ''
	   readcol, mo_dir() + 'files.txt', files, format='A'
	   if files[0] eq '' then continue 
	   if file_test(mo_dir() + 'lastloadedfiles.txt') then begin
	      lastloadedfiles = ''
	      readcol, mo_dir() + 'lastloadedfiles.txt', lastloadedfiles, timelastloaded, format='A,D'   
	      if lastloadedfiles[0] ne '' then stillneeded = 0
	   endif 
	   if keyword_set(stillneeded) then begin
	      lastloadedfiles = files
	      timelastloaded = fltarr(n_elements(files)) - 42
	   endif
	   openw, statuslun, mo_dir() + 'lastloadedfiles.txt', /get_lun
	   if files[0] eq '' then continue
	   for j=0, n_elements(files)-1 do begin
	      	; if it's not up-to-date, load the light curves
		mprint, ' checking ', files[j], ' for new data'
		; THIS IS WHERE WE USE JASON'S INFORMATION TO SKIP SOME STARS?
		; (also, once I'm sure everything as been loaded once, turn this down to just the _daily.fits)
		fi = file_info(files[j])
		match = where(lastloadedfiles eq files[j], nmatch)
		if nmatch gt 1 then stop
	
		if (nmatch eq 0) or (timelastloaded[match] lt fi.mtime) or keyword_set(remake) then begin
		      get_jonathans_lightcurves, files[j], remake=remake
		endif else mprint, ' raw lightcurves in ', files[j], ' are up to date! '
	        printf, statuslun, files[j], systime(/sec)
	    endfor
	    close, statuslun
	    free_lun, statuslun

	endfor
	
END