PRO phase_blind, remake=remake
;+
; NAME:
;	PHASE_BLIND
; PURPOSE:
;	phase up blindly-located candidate transits on a MITTEN-cleaned light curve
; CALLING SEQUENCE:
;	phase_blind, remake=remake
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
	;if is_uptodate(star_dir + 'blind_transits.idl', star_dir + 'blind_transits.idl') then begin
	;print, ' - blind phasing is up to date!'
	;return
	;endif
	
	; skip if no data	
	if has_data(/med) eq 0 then begin
		mprint, skipping_string, 'not enough points to make phased transit search worthwhile!'
		return
	end

	; skip if up-to-date
	if is_uptodate(star_dir + 'blind/folders.idl', star_dir + 'medianed_lc.idl') and keyword_set(remake) eq 0 then begin
		mprint, skipping_string, 'blind phased transit search is up to date!'
		return
	endif

	; skip if there were no initial guesses
	if file_test(star_dir + 'blind/transits.idl') eq 0 then begin
		mprint, skipping_string, 'no blind transit initial guesses were found; giving up!'
		return
	endif

	; load initial guesses, try them
	restore, star_dir + 'blind/transits.idl'
	restore, star_dir + 'medianed_lc.idl'
	if n_tags(transits) eq 1 then begin
		mprint, skipping_string, 'no significant individual transits were found; no phased search!'
		return
	endif

	; run search
	mprint, doing_string, 'performing blind phased transit search from ',strcompress(/remo, n_elements(transits)),' initial guesses!'
	file_delete, star_dir + 'blind/*/', /recursive
	mprint, tab_string, 'removing old search results'
	
	; only go up to five candidates
	if n_elements(transits) gt 5 then transits = transits[0:4]

	; loop through events
	blind_folders = replicate('', n_elements(transits))
	for i=0, n_elements(transits)-1 do begin
		if transits[i].p lt 1.0 then begin
			folder= 'blind/'+strcompress(/remo, i)+'/'
			blind_folders[i] = folder
			transit = transits[i]
			
			file_mkdir, star_dir + folder
			phaseup, transits[i], folder=folder, candidate=candidate
			if i eq 0 then begin
				best_candidate = candidate
				i_best = i
			endif
			
			if candidate.fap lt best_candidate.fap then begin
				best_candidate = candidate
				i_best = i
			endif
			
			; if candidate.chi gt best_candidate.chi then begin
			; best_candidate = candidate
			; i_best = i
			; endif
			;, 1, /time, transit=transits[i], wtitle=star_dir + ' + blind transit #'+strcompress(/remove, i+1)
		endif
	endfor

	; select best candidate
	candidate = best_candidate
	transit = transits[i_best]
	if keyword_set(display) then begin
		plot_candidate, candidate
		if keyword_set(interactive) then plot_events, candidate, /diag
		; plot_transit, transit
	endif
	file_mkdir, star_dir + 'blind/best/'
	file_copy, star_dir + blind_folders[i_best] + '/*', star_dir + 'blind/best/', /recursive, /overwrite
	mprint, '++++++++++++++++++++++++++++++++++++'
	mprint, tab_string, 'best phased candidate was ', blind_folders[i_best]
	mprint, '++++++++++++++++++++++++++++++++++++'
	
	; save, filename=star_dir + folder + 'candidate.idl', candidate
	; save, filename=star_dir + folder + 'initial_guess.idl', transit
	save, filename=star_dir + 'blind/folders.idl', blind_folders

END
