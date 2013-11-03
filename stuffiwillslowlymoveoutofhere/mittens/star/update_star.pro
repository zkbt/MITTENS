PRO update_star, lspm, year, tel, remake=remake, combine=combine, search=search, pdf=pdf, random=random, do_old_stuff=do_old_stuff, fake=fake, profile=profile, nofold=nofold, highres=highres, lenient=lenient, baddatesokay=baddatesokay, all=all

;+
; NAME:
;	update_star
; PURPOSE:
;	go from a MITTENS light curve to a set of possible phased transit candidates, ready to be explored
; CALLING SEQUENCE:
; 	update_star, lspm, [year, tel], remake=remake, combine=combine
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

	common mearth_tools

	if ~keyword_set(all) and ~keyword_set(year) then year = max(possible_years)

	clear

	; get LSPM info
	if keyword_set(lspm) then i = get_lspm_info(lspm)

	; if need be, combine multiple years or telescopes of data
	if keyword_set(combine) then begin
		combine_boxes, lspm;, year=year
	endif else begin
		; set the directories to this star
		set_star, lspm, year, tel, random=random;, combine=combine
	
		; print out basic information on the star to a text file
		if file_test(star_dir() + 'lspm_info.idl') eq 0 then print_star, /quick
	
		; remove obviously bad observations from consideration, bin exposure chunks
		weed_lightcurve, remake=remake, lenient=lenient,  baddatesokay=baddatesokay
		rough_clean
		rough_clean, /use_sin
	
	endelse
	if keyword_set(pdf) and ~keyword_set(nofold) and file_test(star_dir() + 'inprogress.txt') eq 0 then begin
		openw, f, star_dir() + 'inprogress.txt', /get_lun
		printf, f, systime()
		close, f
		free_lun, f

		if has_data( days=1) and keyword_set(pdf) then begin
			lc_to_pdf, remake=remake, highres=highres
		endif
		if has_data(days=2) and keyword_set(fake) then begin
			if keyword_set(display) then display, /off
			if keyword_set(interactive) then interactive, /off
		;	lc_to_pdf, /remake, /fake_setup

			if is_astonly() eq 0 then  fake_pdfs, 50000, remake=remake	
			if is_astonly() eq 0 then fake_triggers, 50000, remake=remake
		endif

		if is_astonly() eq 0 then fold_boxes
		if ~is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') and is_astonly() eq 0 then call_origami_bot
		if ~is_uptodate(star_dir() + 'vartools/roughly_cleaned_toward_flat_lc.ascii.bls', star_dir() + 'target_lc.idl') and is_astonly() eq 0 then run_vartools

		file_delete, star_dir() + 'inprogress.txt', /allow
	endif



; 		if keyword_set(do_old_stuff) then begin
; 			; read calculated bootstrap sample, estimate N_eit from CCDF
; 			estimate_neit, remake=remake
; 			
; 			; decorrelate and filter light curve
; 			clean_lightcurve, remake=remake
; 	
; 			if has_data(/med) and keyword_set(interactive) then begin
; 	;			plot_star
; 				xplot, xsize=800, ysize=1000
; 				plot_lightcurves, /diag, /time
; 				if question('curious?', interactive=interactive) then stop
; 			endif
; 		endif

		;phase_pdf


; 	if has_data(/med,n=30, days=2) and keyword_set(search) then begin
; 	;	xplot
; 	;	plot_lightcurves, /time
; 
; 	
; 		; perform transit search
; 		search_lightcurve, remake=remake
; 		phase_blind, remake=remake
; 		
; ; 		estimate_sensitivity
; ; 		estimate_sensitivity, /gauss
; 		endif	
		close, /all
; 	endif
		if file_test(star_dir() + 'candidates_pdf.idl') then begin
			restore, star_dir() + 'candidates_pdf.idl'
	
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
	openw, f, star_dir() + 'last_reprocessed.txt', /get_lun
	printf, f, systime()
	close, f
	free_lun, f
	
;plot_lightcurves, /time, /eps
;plot_lightcurves, /eps
;; make all the plots!
 ; plot_star, star_dir 
END
