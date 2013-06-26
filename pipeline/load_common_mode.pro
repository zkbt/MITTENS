FUNCTION load_common_mode, remake=remake
;+
; NAME:
;	LOAD_COMMON_MODE
; PURPOSE:
;	load the common mode time series from the MEarth directory; updates "cm.idl" as necessary
; CALLING SEQUENCE:
;	cm = load_common_mode(remake=remake)
; INPUTS:
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	writes "cm.idl" to the main MEarth directory
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
	common mearth_tools
;	filenames = file_search([reduced_dir, '/home/zberta/temp2854/'] + 'common.mode')
	filenames = file_search(reduced_dir + 'common.mode')
	; MAJOR TEMPORARY KLUDGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;	if systime(/jul) gt 2456284.0d then stop

	finished_filenames = ''
	j = file_info(filenames)
	z = file_info('observatory/cm.idl')	
	if max(j.mtime) ge z.mtime or keyword_set(remake) then begin
		for i=0, n_elements(filenames)-1 do begin
			if total(strmatch(finished_filenames, filenames[i])) eq 0  then begin
				info = file_info(filenames[i])
				if info.size gt 0 then begin
					mprint, doing_string, ' loading ', filenames[i]
					r = read_ascii(filenames[i])
					mprint, doing_string, '     adding ', strcompress(/remo, n_elements(r.field1[0,*])), ' points'
		
					cm_old = replicate({mjd_obs:0.0d, flux:0.0, fluxerr:0.0, n:0, n_fields:0}, n_elements(r.field1[0,*]))
					cm_old.mjd_obs = reform(r.field1[0,*])
					cm_old.flux =reform( r.field1[1,*])
					cm_old.n = reform(r.field1[3,*])
					cm_old.fluxerr = reform(r.field1[2,*])/sqrt(cm_old.n)
					cm_old.n_fields = reform(r.field1[4,*])
					if n_elements(cm) eq 0 then cm = cm_old else cm = [cm_old, cm]
					finished_filenames = [finished_filenames, filenames[i]]			
				endif
			endif
		endfor
		cm = cm[sort(cm.mjd_obs)]
		save, filename='observatory/cm.idl', cm
	endif else  restore, 'observatory/cm.idl'
	return, cm
END