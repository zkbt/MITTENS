PRO search_lightcurve, remake=remake
;+
; NAME:
;	SEARCH_LIGHTCURVE
; PURPOSE:
;	run transit search on a MITTEN-cleaned light curve
; CALLING SEQUENCE:
;	search_lightcurve, remake=remake
; INPUTS:
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
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

	common this_star
	common mearth_tools
	if file_test(star_dir + 'blind/') eq 0 then file_mkdir, star_dir + 'blind/'

	; skip if not enough data
	if has_data(/med) eq 0 then begin
		mprint, skipping_string, 'not enough points to make single transit search worthwhile!'
		return
	end

	; skip if search is up-to-date
	if is_uptodate(star_dir + 'blind/transits.idl', star_dir + 'medianed_lc.idl') and not keyword_set(remake) then begin
		mprint, skipping_string, 'individual transit search is up to date!'
		return
	endif

	; do initial search for individual events
	mprint, doing_string, 'searching ', star_dir, ' for individual transits'
	restore, star_dir + 'medianed_lc.idl'
	threshold = 1.0/n_elements(medianed_lc)
	while(n_tags(transits) le 1) do begin
		threshold *= 2.0
		transits = find_the_transit(medianed_lc, threshold=threshold, /all)
	endwhile
	
	;for i=0, n_elements(transits)-1 do begin
	;if transits[i].p lt 1.0 then begin
	; ; plot_lightcurves, 1, /time, transit=transits[i], wtitle=star_dir + ' + blind transit #'+strcompress(/remove, i+1)
	;endif
	;endfor

	; save results as initial guess for light curve phasing routine
	if n_tags(transits) ge 1 then begin
		mprint, tab_string, string(n_elements(transits), format='(I10)'), ' individual transit events found with (underestimated) FAP < ', string(format='(F6.4)', threshold)
		save, transits, filename=star_dir + 'blind/transits.idl'
	endif

END
