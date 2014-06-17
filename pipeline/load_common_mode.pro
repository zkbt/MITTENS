FUNCTION load_common_mode, which_observatory, remake=remake
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
	if n_elements(which_observatory) eq 0 then begin
		mprint, error_string, "load_common_mode.pro needs you to specify a MEarth observatory (either 'N' or 'S')"
	endif
	if which_observatory ne 'N' and which_observatory ne 'S' then begin
		mprint, error_string, which_observatory, ' is not a valid observatory!'
		stop
	endif
	observatories_to_match = which_observatory;['N', 'S']
	for o=0, n_elements(observatories_to_match)-1 do begin
		i_match = where(observatories eq observatories_to_match[o], n_match)
		if n_match eq 0 then continue
		
		filenames = file_search(reduced_dir[i_match] + 'common.mode')
		
		; MAJOR TEMPORARY KLUDGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	;	if systime(/jul) gt 2456284.0d then stop
	
		finished_filenames = ''
		j = file_info(filenames)
		z = file_info('observatory_'+observatories_to_match[o]+'/cm.idl')	
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
			save, filename='observatory_'+observatories_to_match[o]+'/cm.idl', cm
		endif else  restore, 'observatory_'+which_observatory + '/cm.idl'
	endfor
	return, cm
END