PRO marplify, lspm, old=old, remake=remake, year=year, fake=fake, nofold=nofold, bulldoze=bulldoze, trimtransits=trimtransits
;+
; NAME:
;	marplify
; PURPOSE:
;	go from a MITTENS light curve to a set of possible phased transit candidates, ready to be explored
; CALLING SEQUENCE:
; 	marplify, lspm, [year, tel], remake=remake, combine=combine
; INPUTS:
;	lspm = lspm number of the star to update
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
;	sometime between 2008 and 2011.
;-

	; grab MEarth variables
	common mearth_tools
	clear

; 	; get LSPM info
; 	if keyword_set(lspm) then i = get_lspm_info(lspm)


	; by default, just look at the star from within this year
	if keyword_set(old) then begin
		year_string = '*' 
	endif else begin
		if keyword_set(year) then year_to_consider = year else year_to_consider = max(possible_years)
		year_string = string(form='(I02)', year_to_consider mod 2000)
	endelse

	; pick out all directories that have data for this star (possibly confined to this star)
	matching_directories = 'ls'+string(lspm, format='(I04)')+'/ye'+year_string+'/te0*/'
	f = file_search(matching_directories, /mark_dir)

	; make variables subdividing the relevent star_dirs
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))

	; loop over telescope(-years) to update MITTEN light curves, run a first pass of lc_to_pdf
	for i=0, n_elements(f)-1 do begin
		
		; switch into this star
		set_star, ls[i],  ye[i], te[i]
		process_staryete

		if n_elements(radii) lt 6 then stop
	endfor

	; stop here, if just doing fakes -- a bit of a hack
	if keyword_set(nofold) and keyword_set(fake) then return ;(won't write a new last_reprocessed!)

	; take the MarPLEs that were just calculated and combine them into one 
	combine_boxes, lspm, year=year_to_consider
	set_star, lspm, year_to_consider, /comb
	
	; if there's no combined PDF, then skip to next star
	if file_test(star_dir() + 'box_pdf.idl') eq 0 then begin
		mprint, 'no combined PDF could be constructed for ', star_dir()
		mprint, skipping_string, 'skipping to next star'
		return
	endif

	; run the phased search on the combined PDF timeseries
	if is_astonly() eq 0 and ~keyword_set(nofold)  then begin
		if file_test(star_dir() + 'inprogress.txt') eq 0 then begin 
			; make a temporary file to prevent duplication of effort for this long step
			openw, lun, star_dir() + 'inprogress.txt', /get_lun
			spawn, 'hostname', hostname
			printf, lun, hostname
			printf, lun, systime()
			close, lun
			free_lun, lun
	
			if ~is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') or ~is_uptodate(star_dir() +  'octopus_candidates_pdf.idl', star_dir() + 'box_pdf.idl')  then call_origami_bot
	;		fold_boxes
			file_delete, star_dir() + 'inprogress.txt', /allow
		endif 
	endif

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
	candidate_filename =  'octopus_candidates_pdf.idl'
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
END
