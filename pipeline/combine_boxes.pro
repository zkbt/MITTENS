PRO combine_boxes, lspm, remake=remake, now=now, year=year

	common mearth_tools
	lspm_dir = 'ls'+string(format='(I04)', lspm)+'/'
	ls_string = 'ls'+string(format='(I04)', lspm)
	if keyword_set(year) then begin
		ye_string = 'ye' + string(format='(I02)', year mod 2000)
		f = file_search(lspm_dir +'/'+ ye_string + '/te*/', /mark_dir)
	endif else begin
		f = file_search(lspm_dir + 'ye*/te*/', /mark_dir)
	endelse
	if keyword_set(year) then begin
		star_dir = ls_string + '/'+ye_string + '/combined/' 
	endif else star_dir = ls_string + '/combined/'


	

	; don't remake, if the combined PDF is more recent than the uncombined PDF's
	if min(is_uptodate(star_dir + 'box_pdf.idl', f+'box_pdf.idl')) gt 0 then begin
		mprint, 'the combined PDF is more recent than all of the uncombined ones!'
		mprint, skipping_string, 'not merging!'
		return
	endif
	
	if file_test(star_dir) eq 0 then file_mkdir, star_dir

	starttime = systime(/sec)
	mprint, ' merging...'
; 	if ~keyword_set(now) then begin
; 		for i=0, n_elements(f)-1 do begin
; 			star_dir = f[i]
; 			update_star, /pdf, remake=remake, long(stregex(/ex, stregex(/ex, star_dir, 'ls[0-9]+'), '[0-9]+')),long(stregex(/ex, stregex(/ex, star_dir, 'ye[0-9]+'), '[0-9]+')),long(stregex(/ex, stregex(/ex, star_dir, 'te[0-9]+'), '[0-9]+'))
; 		endfor
; 	endif
	for i=0, n_elements(f)-1 do begin
		this_star_dir = f[i]
		
		; skip the astrometric only data
		if file_test(this_star_dir + 'astonly.txt') then continue

		mprint, tab_string, this_star_dir
		if file_test(this_star_dir+ 'box_pdf.idl') then begin
			
			restore, this_star_dir + 'box_pdf.idl'
			if n_elements(big_boxes) eq 0 then big_boxes = boxes else big_boxes = [big_boxes,boxes]
			if n_elements(mincadence) eq 0 then mincadence = min(boxes[1:*].hjd - boxes.hjd) else mincadence = min(boxes[1:*].hjd - boxes.hjd) < mincadence

			restore, this_star_dir + 'inflated_lc.idl'
			if n_elements(big_inflated_lc) eq 0 then big_inflated_lc = inflated_lc else big_inflated_lc = [big_inflated_lc, inflated_lc]

			restore, this_star_dir + 'ext_var.idl'
			if n_elements(big_ext_var) eq 0 then big_ext_var = ext_var else big_ext_var = [big_ext_var, ext_var]

			restore, this_star_dir + 'raw_target_lc.idl'
			if n_elements(raw_big_target_lc) eq 0 then raw_big_target_lc = target_lc else raw_big_target_lc = [raw_big_target_lc, target_lc]

			restore, this_star_dir + 'raw_ext_var.idl'
			if n_elements(raw_big_ext_var) eq 0 then raw_big_ext_var = ext_var else raw_big_ext_var = [raw_big_ext_var, ext_var]

			mprint, tab_string, n_elements(ext_var), ' raw light curve points'
			mprint, tab_string, n_elements(inflated_lc), ' binned light curve points'
			mprint, tab_string, n_elements(boxes), ' boxes'

			if file_test(star_dir + 'pos.txt') eq 0 then begin
				if file_test(star_dir) eq 0 then file_mkdir, star_dir
				file_copy, this_star_dir + 'pos.txt', star_dir, /over
			endif

$`
;			restore, star_dir + 'sfit.idl'
		endif

	endfor
	if n_elements(big_boxes) eq 0 then begin
		mprint, 'there were no non-astrometric datasets to combine'
		mprint, skipping_string, 'not saving a combined PDF'
		return
	end

;	star_dir = lspm_dir + 'combined/'
	mprint, ' ... into ', star_dir

	; resort, and combine overlapping box estimates
	i = sort(big_boxes.hjd)
	boxes = big_boxes[i]
	smoothed_boxes = boxes
	for i=0, n_elements(boxes[0].depth)-1 do begin
		j = where(boxes.n[i] gt 0, n_ok)
		if n_ok gt 0 then begin
			temp = weighted_mean_smooth(boxes[j].hjd, boxes[j].depth[i], boxes[j].depth_uncertainty[i], time=0.5/60.0/24.0)
			smoothed_boxes[j].depth[i] = temp.y
			smoothed_boxes[j].depth_uncertainty[i] = temp.err
		endif
	endfor
; 		;	plot, 24*60*(smoothed_boxes[1:*].hjd - smoothed_boxes.hjd), /yno,  yr=[-10,10], psym=3
			i = where(smoothed_boxes[1:*].hjd - smoothed_boxes.hjd gt 1.0/60.0/60.0/24.0, n_uniq)
			boxes = smoothed_boxes[i]
			oplot, i, 24*60*(boxes[1:*].hjd - boxes.hjd), color = 250
;			if question(/int, 'aeh') then stop
	;i = uniq(smoothed_boxes.hjd, sort(smoothed_boxes.hjd)
	

	boxes = smoothed_boxes[i]
	plot_boxes, boxes

	i = sort(big_inflated_lc.hjd)
	inflated_lc = big_inflated_lc[i]
	ext_var = big_ext_var[i]

		wait, 1.0 - (systime(/sec) - starttime) > 0.0
	save, filename=star_dir + 'box_pdf.idl', boxes
	save, filename=star_dir + 'inflated_lc.idl', inflated_lc
	save, filename=star_dir + 'ext_var.idl', ext_var
;	save, filename=star_dir + 'sfit.idl', sfit
		
	i = sort(raw_big_target_lc.hjd)
	ext_var = raw_big_ext_var[i]
	save, filename=star_dir + 'raw_ext_var.idl', ext_var
	target_lc = raw_big_target_lc[i]
	save, filename=star_dir + 'raw_target_lc.idl', target_lc

	set_star, lspm, year, /comb
END