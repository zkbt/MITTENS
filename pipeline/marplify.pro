PRO marplify, input_mo, old=old, remake=remake, fake=fake, nofold=nofold, bulldoze=bulldoze, trimtransits=trimtransits
;+
; NAME:
;	marplify
; PURPOSE:
;	go from a MITTENS light curve to a set of possible phased transit candidates, ready to be explored
; CALLING SEQUENCE:
; 	marplify, lspm, [year, tel], remake=remake, combine=combine
; INPUTS:
;	mo = ID of the MEarth object to update
;	year = year, starting at the end of the monsoon (optional, defaults to current year)
;	tel = telescope (optional, defaults to tel0N with smallest N)
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
;	/combined = search combined light curves as well as individual years 
; OUTPUTS:
;	*seriously* messes around with the file structure in ls[lspm]/ye[year]/te[tel]/
; RESTRICTIONS:
; EXAMPLE:
; 	update_star, 1186, 8, 1
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2041.
;-

	; grab MEarth variables
	common mearth_tools
	clear

	; clean up the MO, convert if necessary
	if keyword_set(input_mo) then desired_mo = name2mo(input_mo)

	; if mo wasn't specified, grab it from the current directory
	if ~keyword_set(desired_mo) then desired_mo = name2mo(mo_dir())

	; by default, just look at the star from within this year
	year_string = '*' 

	; pick out all directories that have data for this star (possibly confined to this star)
	matching_directories = mo_prefix+desired_mo+'/ye'+year_string+'/te*/'
	f = file_search(matching_directories, /mark_dir)

	; make variables subdividing the relevent star_dirs
	mo = name2mo(f)
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))

	if f[0] ne '' then begin
		; loop over telescope(-years) to update MITTEN light curves, run a first pass of lc_to_pdf
		for i=0, n_elements(f)-1 do begin
			
			if mo[i] eq '' then stop
			; switch into this star
			set_star, mo[i],  ye[i], te[i]
			
			thesubdirectoryneedsremaking = file_test(star_dir() + 'needtomakemarple') 
			thecomboneedsremaking =  file_test(mo_dir() + 'combined/' + 'needtomakemarple') 
			process_staryete, nofold=nofold, remake=keyword_set(remake) or thesubdirectoryneedsremaking or thecomboneedsremaking, bulldoze=bulldoze
	
			if n_elements(radii) lt 6 then stop
		endfor
	endif

	; stop here, if just doing fakes -- a bit of a hack
	if keyword_set(nofold) and keyword_set(fake) then return ;(won't write a new last_reprocessed!)

	; take the MarPLEs that were just calculated and combine them into one 
	combine_boxes, desired_mo, year=year_to_consider
	set_star, desired_mo, year_to_consider, /comb
	
	; if there's no combined PDF, then skip to next star
	if file_test(star_dir() + 'box_pdf.idl') eq 0 then begin
		mprint, 'no combined PDF could be constructed for ', star_dir()
		mprint, skipping_string, 'skipping to next star'
		return
	endif

; ; 	run the phased search on the combined PDF timeseries
; 	if is_astonly() eq 0 and ~keyword_set(nofold)  then begin
; 		if file_test(star_dir() + 'inprogress.txt') eq 0 then begin 
; 			make a temporary file to prevent duplication of effort for this long step
; 			openw, lun, star_dir() + 'inprogress.txt', /get_lun
; 			spawn, 'hostname', hostname
; 			printf, lun, hostname
; 			printf, lun, systime()
; 			close, lun
; 			free_lun, lun
; 	
; 		if ~is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') or ~is_uptodate(star_dir() +  'octopus_candidates_pdf.idl', star_dir() + 'box_pdf.idl')  then call_origami_bot
; 			fold_boxes
; 			file_delete, star_dir() + 'inprogress.txt', /allow
; 		endif 
; 	endif

	; summarize the statistics in fast-reading files
	candidate_filename =  'candidates_pdf.idl'
	if file_test(star_dir() + candidate_filename) then begin
		restore, star_dir() + candidate_filename
		restore, star_dir() + 'box_pdf.idl'
		stats = {boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}
		stats.boxes[*] = total(boxes.n[*] gt 0, 2)
		stats.points_per_box =  total(boxes.n[*], 2)/ total(boxes.n[*] gt 0, 2)
		restore, star_dir() + 'inflated_lc.idl'
		stats.points = n_elements(inflated_lc)
		stats.start = min(inflated_lc.hjd)
		stats.finish = max(inflated_lc.hjd)
		restore, star_dir() + 'spectrum_pdf.idl'
		stats.periods_searched = long(n_periods)
		save,filename=star_dir() + 'stat_summary.idl', stats
	endif
	candidate_filename = typical_candidate_filename;  'octopus_candidates_pdf.idl'
	if file_test(star_dir() + candidate_filename) then begin
		restore, star_dir() + candidate_filename
		restore, star_dir() + 'box_pdf.idl'
		stats = {boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}
		stats.boxes[*] = total(boxes.n[*] gt 0, 2)
		stats.points_per_box =  total(boxes.n[*], 2)/ total(boxes.n[*] gt 0, 2)
		restore, star_dir() + 'inflated_lc.idl'
		stats.points = n_elements(inflated_lc)
		stats.start = min(inflated_lc.hjd)
		stats.finish = max(inflated_lc.hjd)
		stats.periods_searched = file_lines(star_dir() + 'boxes_all_durations.txt.bls')
		save,filename=star_dir() + 'octopus_stat_summary.idl', stats
	endif

	; print a timestamp to a file
	openw, lun, star_dir() + 'last_reprocessed.txt', /get_lun
	printf, lun, systime()
	close, lun
	free_lun, lun
	close, /all
	file_delete, star_dir() + 'needtomakemarple', /allow
END
