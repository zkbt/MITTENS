PRO fold_boxes, remake=remake, n_peaks=n_peaks, p_min=p_min, p_max=p_max, profile=profile, highres=highres
;+
; NAME:
;	PHASE_PDF 
; PURPOSE:
;	phase up any individual transit
; CALLING SEQUENCE:
;	phaseup, transit, n_lc=n_lc, n_peaks=n_peaks, eps=eps, folder=folder, candidate=candidate, fast=fast, lc=lc
; INPUTS:
;	transit = structure containing anchoring event
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	n_lc=n_lc, n_peaks=n_peaks, eps=eps, folder=folder, candidate=candidate, fast=fast, lc=lc
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

	; diagnose the slow bits (probably occultnl)
	if keyword_set(profile) then begin
		profiler, /reset
		profiler, /system
		profiler
		fold_boxes, remake=remake, n_peaks=n_peaks, p_min=p_min, p_max=p_max
		profiler, /report, output=output, data=data
		i = reverse(sort(data.time)) 
		print_struct, data[i[0:10]]
;		if question('do you want to look at the profiler results?', /int) then stop
		return
	endif


	; get settings and parameters
	common mearth_tools
	common this_star
	@filter_parameters
	
	; avoid duplication of effort, don't rerun phase_pdf unless specifically asked
	if is_uptodate(star_dir + 'candidates_pdf.idl', star_dir + 'box_pdf.idl') and not keyword_set(remake) then begin
    		mprint, skipping_string, 'phasing PDF is up-to-date'
		return
	endif

	; quit if lc_to_pdf hasn't happened yet
	if file_test(star_dir + 'box_pdf.idl') eq 0 then begin
		mprint, skipping_string, " lc_to_pdf hasn't been run on ", star_dir
		return
	endif


	; load boxes adn inflated light curve
	restore, star_dir + 'box_pdf.idl'
	restore, star_dir + 'inflated_lc.idl'
	lc = inflated_lc
	
	; set up plotting, if desired
	if keyword_set(display) then begin
		; plot singletons
		cleanplot, /silent
		loadct, 39, /silent
; 		xplot, 3, title='S/N for "Box" Events', xsize=1000, ysize=300
; 		plot_boxes, boxes
	endif

	; set the number of peaks (starting points) to try 
	if not keyword_set(n_peaks) then n_peaks = 5

	; the number of different depth measurements included for each box
	n_depths = n_elements(boxes[0].depth)
	n_durations = n_depths

	; find the best boxes for each duration, to use as epochs for the phased search
	i_startingbox = intarr(n_depths, n_peaks)
	for i=0, n_depths-1 do begin
		; only look at boxes that include >0 observations
		i_interesting = where(boxes.n[i] gt 0, n_interesting)

		; create S/N spectrum for a given duration
		sn = boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]

		; set the starting boxes for this duration to the peaks of that S/N spectrum
		i_startingbox[i,*] = i_interesting[select_peaks(sn, n_peaks, n_sigma=1)]
	endfor
 
	; SOMETHING TO DO!
	; add a keyword to phase up to a specified moment (i.e., see what's consistent with a particular trigger....)
	
	; period range to consider (days)
	if not keyword_set(p_min) then p_min = (3.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.25
	if not keyword_set(p_max) then p_max = 50.0
	
	; convert to frequency range (inverse days), bins set to capture 5 minute resolution phased over the whole data set
;	v_min = 1.0d/p_max
;	v_max = 1.0d/p_min
;	v_bin = 5.0d/60.0/24.0/(max(lc.hjd) - min(lc.hjd))

	; construct period search array (uniform in logP ensures constant max misalignment over season)
	max_misalign = 5.0/60.0/24.0
	if keyword_set(highres) then max_misalign = 2.5/60.0/24.0
	data_span = max(lc.hjd) - min(lc.hjd)
	n_periods = data_span/max_misalign*alog(p_max/p_min)
	periods = p_min*exp(max_misalign/data_span*dindgen(n_periods))
	dp = periods[1:*] - periods
	squashed_sn = fltarr(n_periods)

	; use physical information to set *maximum* duration at a given period
	mass = lspm_info.mass
	radius = lspm_info.radius
	a_over_r = 4.2/radius*mass^(1.0/3.0)*periods^(2.0/3.0)
	radius_could_be_underestimated_by = 1.2
	maxdurations = radius_could_be_underestimated_by*periods/a_over_r/!pi;4.0

	; set indices to point to the maximum duration for each period 
	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_maxduration = value_locate(boxes[0].duration-duration_bin/2, maxdurations)	

	; define the night for each data point (an integer, should turn over at midday)
 	nights = round(boxes.hjd -mearth_timezone())


	; print out details of search
	mprint, tab_string, doing_string, 'searching ', strcompress(/remo, n_periods), ' periods from ', string(format='(F4.2)', p_min), ' to ', strcompress(/remo, string(format='(F5.2)', p_max))

	; set a padding integer, to be used in phase folding (faster than modding)
	pad = long((max(lc.hjd) - min(lc.hjd))/p_min)+1

 n_save = 10

	; create struct to contain candidates
	;candidates =;replicate({period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0}, n_periods, n_peaks, n_durations) 
  peak_candidates = replicate({period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0}, n_peaks, n_durations, n_save) 

	; plot process in action
	if keyword_set(display) and keyword_set(interactive) then begin
		cleanplot, /silent
		xplot, 6, xsize=1000, ysize=300, title=star_dir()
	endif

	; loop over the number of peaks we want to find
	for j=0, n_peaks-1 do begin
		
		; loop over durations (effectively impact parameter)
		for k=0, n_durations-1 do begin
			temp_candidates = replicate({period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0}, n_periods)
			
			; loop over periods
			for i=0L, n_periods-1 do begin

				; only run if duration is physically plausible
				if k le i_maxduration[i] then begin

					; phase time to the appropriate period
					temp_candidates[i].period = periods[i]
					temp_candidates[i].duration = boxes[0].duration[k];maxdurations[i]
					temp_candidates[i].hjd0 = boxes[i_startingbox[k, j]].hjd
					temp_candidates[i] = box_folding_robot(temp_candidates[i], boxes, nights=nights, pad=pad, k=k)
				endif
				if not keyword_set(interactive) and i mod 1000 eq 0 then counter, i, n_periods, /timeleft, starttime=starttime, $
					tab_string + $
					' duration '+ rw(k+1) + ' of ' + rw(n_durations) + ' | ' +$
					' epoch ' + rw(j+1) + ' of ' + rw(n_peaks) + ' | ' +$
					' period '	
			endfor
			; find peaks in each subset's period spectrum
			sn = temp_candidates.depth/temp_candidates.depth_uncertainty
			if total(finite(sn)) gt 0 then begin
				i_finite = where(finite(sn))
				squashed_sn[i_finite] = squashed_sn[i_finite] > sn[i_finite]

				; pick peaks, store for each of n_peak, n_durations, n_save
				period_peaks = i_finite[select_peaks(sn[i_finite], n_save, /reverse)]
				peak_candidates[j,k,*] = temp_candidates[period_peaks]
				if keyword_set(display) then begin
					temp = max(peak_candidates.depth/peak_candidates.depth_uncertainty, index, /nan)
					best_candidate = peak_candidates[index]
					if k eq 0 then begin
						cleanplot, /silent
						loadct, 39, /silent
						xplot, 7, title=star_dir(), xsize=700, ysize=750
					endif
					erase
					smultiplot, /init, [1,4], ygap=0.03, xgap=0.0, rowhe=[1,.2, 1,1]
					smultiplot, /dox
					; plot spectrum
					plot, 1.0/temp_candidates.period, temp_candidates.depth/temp_candidates.depth_uncertainty, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('Phased Transit S/N (\sigma)'), xtick_get=xtick_get, ymargin=[4,4], charsize=1, xmargin=[6,2], xrange=1/[p_max, p_min], yrange=[0,max(peak_candidates.depth/peak_candidates.depth_uncertainty)], /nodata
					oplot, 1.0/temp_candidates.period, temp_candidates.depth/temp_candidates.depth_uncertainty
					axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F5.1)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
					plots, 1/peak_candidates.period, peak_candidates.depth/peak_candidates.depth_uncertainty, color=250, psym=8
					plots, 1/best_candidate.period, best_candidate.depth/best_candidate.depth_uncertainty, color=250, psym=8, symsize=2
					smultiplot

					; plot best phased candidate
					k_best =  value_locate(boxes[0].duration-duration_bin/2, best_candidate.duration)  
					i_interesting = where(boxes.n[k_best] gt 0, n_interesting)
					i_intransit = i_interesting[where_intransit(boxes[i_interesting], best_candidate, n_it, /boxes)];buffer=-best_candidate.duration/4
					phased_time = (boxes.hjd - mean(best_candidate.hjd0))/mean(best_candidate.period) + pad + 0.5
					orbit_number = long(phased_time)
					phased_time = (phased_time - orbit_number - 0.5)*mean(best_candidate.period)
					
					i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
					h = histogram(nights[i_intransit], reverse_indices=ri)
					ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
					uniq_intransit =(ri[ri_firsts])
					
					smultiplot, /dox
					yr = reverse(range(boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best]))
					yr = yr < (3*best_candidate.depth)
					yr = yr > (-3*best_candidate.depth)
					loadct, 0, /silent
					plot, 24*phased_time[i_interesting], boxes[i_interesting].depth[k_best], psym=8, yrange=yr, xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata, xr=[-best_candidate.period/2, best_candidate.period/2]*24, xmargin=[30,5]
					oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best], color=150, errcolor=150, psym=8
					hline, 0, linestyle=1
					vline, -best_candidate.duration/2*24, linestyle=2
					vline, best_candidate.duration/2*24, linestyle=2
					oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k_best], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k_best],  psym=8, symsize=2
					loadct, 39, /silent
					oploterror, best_candidate.depth, best_candidate.depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
					
					smultiplot, /dox
					loadct, 0, /silent
					ploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best], xr=24*[-best_candidate.duration, best_candidate.duration]*3, psym=8, yrange=yr, xtitle='Phased Time (hours)',/nodata, xmargin=[30,5]
					oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[k_best], boxes[i_interesting].depth_uncertainty[k_best], color=150, errcolor=150, psym=8
					hline, 0, linestyle=1
					vline, -best_candidate.duration/2*24, linestyle=2
					vline, best_candidate.duration/2*24, linestyle=2
					oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k_best], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k_best],  psym=8, symsize=2
					loadct, 39, /silent
					oploterror, best_candidate.depth, best_candidate.depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
					smultiplot, /def
				endif      
			endif     
		endfor
		; compress over the epochs (leaves as n_durations x n_save array)
		maxes = max(peak_candidates.depth/peak_candidates.depth_uncertainty, peaks, dim=1)
		finite_candidates = peak_candidates[peaks[where(peak_candidates[peaks].depth_uncertainty gt 0, n_finite)]]
		i_sorted = reverse(sort(finite_candidates.depth/finite_candidates.depth_uncertainty))
		best_candidates = finite_candidates[i_sorted[0:(n_save < n_finite)-1]]
		
		if keyword_set(display) then begin
			xplot, 6, title=star_dir(), xsize=500, ysize=300
			plot, best_candidates.depth/best_candidates.depth_uncertainty, /yno, psym=-8, xs=3, ys=3, xtitle='Rank', ytitle='S/N'
			xyouts, orient=30,  indgen(n_elements(best_candidates))+0.2,  best_candidates.depth/best_candidates.depth_uncertainty, string(best_candidates.period, form='(F5.2)') + ' days!C'+string(best_candidates.depth, form='(F5.3)')+goodtex('\pm') +string(best_candidates.depth_uncertainty, form='(F5.3)')
		endif
		
		; save results
		save, filename=star_dir + 'candidates_pdf.idl', best_candidates
		n_boxes = n_elements(boxes)
		n_datapoints = n_elements(lc)
		save, filename=star_dir + 'spectrum_pdf.idl' , p_max, p_min, n_periods, n_durations, n_boxes, n_datapoints, max_misalign, data_span, squashed_sn
	endfor



END