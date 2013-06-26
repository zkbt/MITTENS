PRO process_staryete, bulldoze=bulldoze, remake=remake, lenient=lenient,  baddatesokay=baddatesokay, trimtransits=trimtransits, fake=fake, nofold=nofold
	common mearth_tools
	common this_star

		; skip star if there's no data
		if file_test(star_dir() + 'raw_target_lc.idl') eq 0 then begin
			mprint, skipping_string, 'no raw light curve file was found in ' + star_dir() + '; skipping!'
			return
		endif
	
		if keyword_set(bulldoze) then file_delete, star_dir() + 'inprogress.txt', /allow
		if file_test(star_dir() + 'inprogress.txt') eq 0 then begin 
			; make a temporary file to prevent duplication of effort for this long step
			openw, lun, star_dir() + 'inprogress.txt', /get_lun
			spawn, 'hostname', hostname
			printf, lun, hostname
			printf, lun, systime()
			close, lun
			free_lun, lun
	
			; print out basic information on the star to a text file
			if file_test(ls_dir() + 'lspm_info.idl') eq 0 then print_star, /quick
	
			; remove obviously bad observations from consideration, bin exposure chunks
			weed_lightcurve, remake=remake, lenient=lenient,  baddatesokay=baddatesokay, trimtransits=trimtransits
	
			; make a quick, rough attempt at cleaning
			rough_clean
			rough_clean, /use_sin

			; run lc_to_pdf
			if has_data( days=1)  then begin
				lc_to_pdf, remake=remake;, highres=highres
			endif
			if has_data(days=2) and keyword_set(fake) then begin
				if keyword_set(display) then display, /off
				if keyword_set(interactive) then interactive, /off
			;	lc_to_pdf, /remake, /fake_setup
	
 				if is_astonly() eq 0 then fake_pdfs, 60000, remake=remake	
				if is_astonly() eq 0 then fake_triggers, 60000, remake=remake
			endif

; 			; run the phased search on the single-telescope-year PDF timeseries
; 			if is_astonly() eq 0 and ~keyword_set(nofold)  then begin
; 				if ~is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') $
; 				or ~is_uptodate(star_dir() +  'octopus_candidates_pdf.idl', star_dir() + 'box_pdf.idl') $
; 				then call_origami_bot
; 
; 			;	if ~is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl')  then call_origami_bot
; ;			;;	if ~is_uptodate(star_dir() + 'vartools/roughly_cleaned_toward_flat_lc.ascii.bls', star_dir() + 'target_lc.idl') then run_vartools
; 			endif
			file_delete, star_dir() + 'inprogress.txt', /allow

			; print a timestamp to a file
			openw, lun, star_dir() + 'last_reprocessed.txt', /get_lun
			printf, lun, systime()
			close, lun
			free_lun, lun
			close, /all
		endif
		
END