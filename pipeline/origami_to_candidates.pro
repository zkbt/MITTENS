PRO origami_to_candidates, remake=remake, n_save=n_save
	; find peaks in the huge grid search
	common this_star
	common mearth_tools

	if is_uptodate(star_dir + 'octopus_candidates_pdf.idl', star_dir + 'boxes_all_durations.txt.bls') and ~keyword_set(remake) then return
	if ~file_test(star_dir() + "boxes_all_durations.txt.bls") and ~file_test(star_dir() + 'box_pdf.idl') and ~keyword_set(remake)  then return
	restore, star_dir() + 'box_pdf.idl'

; before accounting for antitransits
; ; ; ; 	octopus = read_ascii(star_dir() + "boxes_all_durations.txt.bls")
; ; ; ; 	n_durations = n_elements(octopus.(0)[*,0]) - 1
; ; ; ; 	periods = octopus.(0)[0,*]
; ; ; ; 	multiduration_SN = octopus.(0)[1:n_durations, *]

	mprint, doing_string, 'converting an origami spectrum into a few discrete candidates'
	mprint, tab_string
	octopus = read_ascii(star_dir() + "boxes_all_durations.txt.bls")
	n_durations = (n_elements(octopus.(0)[*,0]) - 1)/2
	periods = octopus.(0)[0,*]
;	multiduration_SN = octopus.(0)[1:n_durations, *]
	multiduration_SN = octopus.(0)[indgen(n_durations)*2+1, *]
	upward_SN = max(octopus.(0)[indgen(n_durations)*2+2, *], dim=1)

	if ~keyword_set(n_save) then n_save = 10
	durations = boxes[0].duration
	candidate_structure = {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0}
	temp_candidate = candidate_structure
	peak_candidates = replicate(candidate_structure, n_durations, n_save) 



	if keyword_set(display) then begin
		cleanplot, /silent
		loadct, 39
		xplot, xsize=1000, ysize=300
		!x.range=range(periods)
		;!p.multi=[0,1,5]
; 		!p.multi=[0,1,4]
; 		; make sure files are sorted from longest to shortest duration
; 		i = reverse(sort(durations))
; 		origami_files = origami_files[i]
; 	;	durations = durations[i]
; 		!x.range=[0.5,10.0]
; 		!y.range=[0,10]
; 		n_durations = n_elements(origami_files)
	
; ; 		plot, octopus.field01[0,*], octopus.field01[1,*], /nodata, xs=3
; ; 		for i=0, n_durations-1 do oplot, octopus.field01[0,*], octopus.field01[n_durations - i,*], color=i*254./n_durations
; ; 
; 		restore, star_dir() + 'spectrum_pdf.idl'
; 		original_periods = p_min*exp(max_misalign/data_span*dindgen(n_periods))
; 		plot, octopus.field01[0,*], max(octopus.field01[1:n_durations-1,*], dim= 1), xs=3
; 		oplot, original_periods, squashed_sn, color=250
; 		stop
; 
; 	
	
; 		for i=0, n_durations-1 do begin
; 			print, origami_files[i]
; 			r = read_ascii(origami_files[i])
; 			if i eq 0 then begin
; 				periods = r.field1[0,*]
; 				periods =  fltarr(n_elements(r.field1[1,*]), n_durations)
; 				power = fltarr(n_elements(r.field1[1,*]), n_durations)
; 				plot, r.field1[0,*], r.field1[1,*], xs=3
; 				oplot, octopus.field01[0,*], octopus.field01[n_durations,*], color=250
; 				plot, r.field1[0,*], r.field1[1,*], /nodata, xs=3
; 	
; 			endif
; 			oplot, r.field1[0,*], r.field1[1,*], color=i*254./n_durations
; 			help, r.field1
; 			periods[0:n_elements(r.field1[0,*])-1,i] = r.field1[0,*]
; 			power[0:n_elements(r.field1[0,*])-1,i] = r.field1[1,*]
; 		endfor
	endif
	for i=0, n_durations-1 do begin
		sn = multiduration_SN[i,*]
		i_finite = where(finite(sn))
		period_peaks = i_finite[select_peaks(sn[i_finite], n_save, pad=10)]	; turned off reverse
	;	print, 'looking  at the ', i, 'th duration; it is ', durations[i]
		for j=0, n_elements(period_peaks)-1 do begin
			peak_candidates[i,j] = find_best_epoch(boxes, periods[period_peaks[j]], durations[i])

		endfor
		plot, periods, sn
		plots, periods[period_peaks], sn[period_peaks], psym=8, color=250
		plots, peak_candidates[i,*].period, peak_candidates[i,*].depth/ peak_candidates[i,*].depth_uncertainty, psym=4, symsize=4, color=150, thick=2
	endfor
	sn = peak_candidates.depth/peak_candidates.depth_uncertainty
	peak_candidates.ratio = -sn/interpol(upward_sn, periods, peak_candidates.period)
	sorted = reverse(sort(sn))
	best_candidates = peak_candidates[sorted[0:n_save-1]]
	save, filename=star_dir + 'octopus_candidates_pdf.idl', best_candidates
	; plot the spectra

	
END