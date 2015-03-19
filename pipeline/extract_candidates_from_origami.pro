PRO extract_candidates_from_origami, remake=remake, n_save=n_save
; 	; find peaks in the huge grid search
	common this_star
	common mearth_tools

	if is_uptodate(star_dir + typical_candidate_filename, star_dir + 'boxes_all_durations.txt.bls') and ~keyword_set(remake) then begin
		mprint, skipping_string + 'candidates are up-to-date with with the origami spectrum; skipping extract_candidates_from_origami'
		return
	endif
	if ~file_test(star_dir() + "boxes_all_durations.txt.bls") and ~file_test(star_dir() + 'box_pdf.idl') and ~keyword_set(remake) then begin
		mprint, skipping_string + 'no origami spectrum was found, so extract_candidates_from_origami cannot be run'
		return
	endif

	restore, star_dir() + 'box_pdf.idl'

; before accounting for antitransits
; ; ; ; 	octopus = read_ascii(star_dir() + "boxes_all_durations.txt.bls")
; ; ; ; 	n_durations = n_elements(octopus.(0)[*,0]) - 1
; ; ; ; 	periods = octopus.(0)[0,*]
; ; ; ; 	multiduration_SN = octopus.(0)[1:n_durations, *]

	mprint, tab_string + doing_string + 'converting an origami spectrum into a few discrete candidates'
	mprint, tab_string + tab_string + doing_string + 'loading ' + star_dir() + "boxes_all_durations.txt.bls"
	mprint, tab_string + tab_string + tab_string + '   (this may take a moment)'

	spawn, 'head -1 ' + star_dir() + "boxes_all_durations.txt.bls", result
	if strmatch(result, 'no phased candidates*') then begin
		mprint, tab_string + tab_string + skipping_string + result
		nothing  = {period:1d8, hjd0:0.0d, duration:0.02, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0, inflation_for_bad_duration:1.0}
		best_candidates = nothing
		save, filename=star_dir + 'octopus_candidates_pdf.idl', best_candidates
		return
	endif
	octopus = read_ascii(star_dir() + "boxes_all_durations.txt.bls")
	n_durations = (n_elements(octopus.(0)[*,0]) - 1)/2
	periods = reform(octopus.(0)[0,*])
;	multiduration_SN = octopus.(0)[1:n_durations, *]
	multiduration_SN = octopus.(0)[indgen(n_durations)*2+1, *]
	upward_multiduration_SN = octopus.(0)[indgen(n_durations)*2+2, *]
	upward_SN = min(upward_multiduration_SN, dim=1)

	if ~keyword_set(n_save) then n_save = 3
	durations = boxes[0].duration
	candidate_structure = {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0, inflation_for_bad_duration:1.0}
	temp_candidate = candidate_structure
	peak_candidates = replicate(candidate_structure, n_durations, n_save) 

	period_grid = ones(n_elements(durations))#periods
	duration_grid = durations#ones(n_elements(periods))

	probability_signal_is_real = 1.0d - exp(sigma_to_logfap(double(multiduration_SN)))
	constrained_logfap = alog(1.0d - probability_signal_is_real*probability_duration_is_okay(period_grid, duration_grid))
	new_SN = logfap_to_sigma(constrained_logfap)

;	cleanplot
;	loadct, 0
;	xplot
;	!p.multi=[0,3,1]
;	!y.range=[0,2]
;	loadct, file='~/zkb_colors.tbl', 65
;	contour, /fill, nlevels=50, (probability_signal_is_real), durations, periods
;	contour, /fill, nlevels=50, (probability_duration_is_okay(periods, durations)),  durations, periods
;	contour, /fill, nlevels=50, 	((probability_signal_is_real)*probability_duration_is_okay(periods, durations)), durations, periods

	
;	cleanplot
;

	SN_of_peaks = fltarr(n_durations, n_save)
	candidate_is_worth_rephasing = bytarr(n_durations, n_save)
	for i=0, n_durations-1 do begin
		; create a one dimensional S/N spectrum at this duration
		sn = new_SN[i,*]

		; figure out where spectrum is reasonable
		i_finite = where(finite(sn))

		; select the peaks from the spectrum
		period_peaks = i_finite[select_peaks(sn[i_finite], n_save, pad=10)]	

		for j=0, n_elements(period_peaks)-1 do begin
			; figure out whether its worthwhile to run find_best_epochs (which is slow)
			temporary_SN = sn[period_peaks[j]]
			temporary_updated_SN = logfap_to_sigma(alog(1.0d - (1.0d - exp(sigma_to_logfap(temporary_SN)))*probability_duration_is_okay(/shh,periods[period_peaks[j]], durations[i])))
		endfor
		SN_of_peaks[i,*] = temporary_updated_SN
	endfor

	; determine a threshold over which candidates are worth rephasing
	sorted = SN_of_peaks[reverse(sort(SN_of_peaks))]
	threshold = sorted[n_save-1]

	mprint, tab_string + tab_string + doing_string + 'looping through periodogram peaks; finding best epochs for each'

	; loop over durations and find the peak periods at each
	;  interesting candidates will have to be re-phase-folded to get their optimum epochs
	for i=0, n_durations-1 do begin

		; skip this duration altogether, if unnecessary
		if total(SN_of_peaks[i,*] ge threshold) eq 0 then continue

		; create a one dimensional S/N spectrum at this duration
		sn = new_SN[i,*]

		; figure out where spectrum is reasonable
		i_finite = where(finite(sn))

		; select the peaks from the spectrum
		period_peaks = i_finite[select_peaks(sn[i_finite], n_save, pad=10)]	

		; loop through these peaks, and find the best epochs at these periods
		for j=0, n_elements(period_peaks)-1 do begin
			; skip phase-folding this particular candidate if unnecessary
			if SN_of_peaks[i,j] ge threshold then begin
				peak_candidates[i,j] = find_best_epoch(boxes, periods[period_peaks[j]], durations[i])
			endif
		endfor

		; apply a correction to the depth uncertainty of the candidates based on duration
		original_SN = peak_candidates[i,*].depth/peak_candidates[i,*].depth_uncertainty
		updated_SN = logfap_to_sigma(alog(1.0d - (1.0d - exp(sigma_to_logfap(original_SN)))*probability_duration_is_okay(/shh,peak_candidates[i,*].period, peak_candidates[i,*].duration)))
		peak_candidates[i,*].inflation_for_bad_duration = original_SN/updated_SN
		peak_candidates[i,*].depth_uncertainty *= peak_candidates[i,*].inflation_for_bad_duration

		; create a plot to show what's going on
		if keyword_set(display) then begin
			cleanplot, /silent
			loadct, 0
			xplot, xsize=1000, ysize=300

			smultiplot, [2,1], colw=[1, 0.3], /init, xgap=0.01
			smultiplot
			!y.range = range([multiduration_SN[i, *], upward_multiduration_SN[i, *]])
			!x.range=range(periods)
			plot, periods, sn, xtitle='Candidate Period (days)', ytitle='Duration-Constrained S/N', /nodata, title=star_dir() + ' | Phase-folded Spectrum for Durations of '+rw(string(durations[i]*24, form='(F5.2)'))+ ' Hours'
			oplot, periods, multiduration_SN[i, *], color=220
			oplot, periods, upward_multiduration_SN[i,*], color=220
			oplot, periods, new_SN[i,*], color=0
			loadct, 39
			plots, periods[period_peaks], sn[period_peaks], psym=8, color=250
			plots, peak_candidates[i,*].period, peak_candidates[i,*].depth/ peak_candidates[i,*].depth_uncertainty, psym=4, symsize=4, color=150, thick=2
			smultiplot
			!x.range =  range(multiduration_SN[i, *])
			plot, multiduration_SN[i, *], new_SN[i,*], psym=3, xtitle='Pre-Constraint S/N'
			oplot, [0,100], [0,100], linestyle=2, color=250
			smultiplot, /def

		endif
	endfor
	sn = peak_candidates.depth/peak_candidates.depth_uncertainty
	peak_candidates.ratio = -sn/interpol(upward_sn, periods, peak_candidates.period)
	sorted = reverse(sort(sn))
	best_candidates = peak_candidates[sorted[0:n_save-1]]
	save, filename=star_dir + typical_candidate_filename, best_candidates
	mprint, tab_string + tab_string + doing_string + 'saving ' + rw(n_save) + ' candidates to ' + star_dir + typical_candidate_filename
	; plot the spectra
	mprint, done_string

END