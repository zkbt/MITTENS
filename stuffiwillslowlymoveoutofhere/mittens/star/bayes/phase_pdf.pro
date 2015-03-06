PRO phase_pdf, remake=remake, n_peaks=n_peaks, p_min=p_min
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
	common mearth_tools
	common this_star
	@filter_parameters
	
	if is_uptodate(star_dir + 'candidates_pdf.idl', star_dir + 'box_pdf.idl') and not keyword_set(remake) then begin
    		mprint, skipping_string, 'phasing PDF is up-to-date'
		return
	endif
	if file_test(star_dir + 'box_pdf.idl') eq 0 then begin
		mprint, skipping_string, " lc_to_pdf hasn't been run on ", star_dir
		return
	endif
	restore, star_dir + 'box_pdf.idl'
	restore, star_dir + 'inflated_lc.idl'
	lc = inflated_lc
	
	if keyword_set(display) then begin
		; plot singletons
		cleanplot, /silent
		loadct, 39, /silent
; 		xplot, 3, title='S/N for "Box" Events', xsize=1000, ysize=300
; 		plot_boxes, boxes
	endif

	if not keyword_set(n_peaks) then n_peaks = 5
	n_depths = n_elements(boxes[0].depth)
	i_bestboxes = indgen(n_depths)
	i_startingbox = intarr(n_depths, n_peaks)
	for i=0, n_depths-1 do begin
		i_interesting = where(boxes.n[i] gt 0, n_interesting)
		i_bestboxes[i] = i_interesting[min(where(boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i] eq max(boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i])))]
		sn = boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]
		i_startingbox[i,*] = i_interesting[select_peaks(sn, n_peaks, n_sigma=1)]
; 		plot, sn 
; 		plots, i_startingbox[i,*], sn[i_startingbox[i,*]], psym=8, color=250
; 		if question(/int, 'hasfha') then stop
	endfor
 
	; add a keyword to phase up to a specified moment (i.e., see what's consistent with a particular trigger....)
	
	
	; period range to consider (days)
	if not keyword_set(p_min) then p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
	p_max = 50.0
	
	; convert to frequency range (inverse days)
	v_min = 1.0d/p_max
	v_max = 1.0d/p_min
	v_bin = 5.0d/60.0/24.0/(max(lc.hjd) - min(lc.hjd))

	; construct period search array
	n_periods = long((v_max - v_min)/v_bin) + 1
	periods = 1.0/(dindgen(n_periods)*v_bin + v_min)
	
	; use physical information
	mass = lspm_info.mass
	radius = lspm_info.radius
	a_over_r = 4.2/radius*mass^(1.0/3.0)*periods^(2.0/3.0)
	durations = periods/a_over_r/4.0 ;fltarr(n_periods) + transit.duration;
	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_durations = value_locate(boxes[0].duration-duration_bin/2, durations)	
; 	depth = transit.depth
; 	it_level = fltarr(n_periods)
; 	oot_level = fltarr(n_periods)
; 	deltachi = fltarr(n_periods)
; 	n_nights = fltarr(n_periods)
 	nights = round(boxes.hjd -mearth_timezone())



	n = intarr(n_periods)
	mprint, tab_string, doing_string, 'searching ', strcompress(/remo, n_periods), ' periods from ', string(format='(F4.2)', p_min), ' to ', strcompress(/remo, string(format='(F5.2)', p_max))
	pad = long((max(lc.hjd) - min(lc.hjd))/p_min)+1
	candidates =replicate({period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0}, n_periods, n_peaks) 
	if keyword_set(display) and keyword_set(interactive) then begin
		cleanplot, /silent
		xplot, 6, xsize=1000, ysize=300, title='Phasing Up Individual Boxes'
	endif
	for j=0, n_peaks-1 do begin
		mprint, tab_string, tab_string, strcompress(/remo, j+1), ' /', strcompress(/remo, n_peaks)
		for i=0L, n_periods-1 do begin
			starting_box = boxes[i_startingbox[i_durations[i], j]]
			; phase time to the appropriate period
			candidates[i,j].period = periods[i]
			candidates[i,j].duration = durations[i]
			candidates[i,j].hjd0 = starting_box.hjd
	

			i_interesting = where(boxes.n[i_durations[i]] gt 0, n_interesting)
			i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidates[i,j], n_it, buffer=-candidates[i,j].duration/4)]
			phased_time = (boxes.hjd - candidates[i,j].hjd0)/periods[i] + pad + 0.5
			orbit_number = long(phased_time)
			phased_time = (phased_time - orbit_number - 0.5)*periods[i]
	
		; YOU'RE WORKING RIGHT HERE!
			i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
			h = histogram(nights[i_intransit], reverse_indices=ri)
			ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
		;	ri_lasts =ri[uniq(ri[0:n_elements(h)-1])+1]-1
			uniq_intransit =(ri[ri_firsts]); + ri[ri_firsts])/2; ri[((ri_firsts +ri_lasts)/2.)]

			candidates[i,j].depth = total(boxes[i_intransit[uniq_intransit]].depth[i_durations[i]]/boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[i]]^2)/ total(1.0/boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[i]]^2)
			candidates[i,j].depth_uncertainty = 1.0/sqrt(total(1.0/boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[i]]^2))
			chi_sq = total(((boxes[i_intransit[uniq_intransit]].depth[i_durations[i]] - candidates[i,j].depth)/boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[i]])^2)
			candidates[i,j].n_boxes = n_elements(uniq_intransit)
			candidates[i,j].n_points = total(boxes[i_intransit[uniq_intransit]].n[i_durations[i]], /int)
			if candidates[i,j].n_boxes gt 1 then begin		
				candidates[i,j].rescaling =  sqrt((chi_sq/(candidates[i,j].n_boxes -1) > 1.0))
				candidates[i,j].depth_uncertainty *= candidates[i,j].rescaling
			endif

			if keyword_set(display) and keyword_set(interactive) then begin
				loadct, 0, /silent
				ploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[i]], boxes[i_interesting].depth_uncertainty[i_durations[i]], xr=24*[-durations[i], durations[i]]*3, psym=8, yrange=reverse(range(boxes[i_interesting].depth[i_durations[i]], boxes[i_interesting].depth_uncertainty[i_durations[i]])), xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata
				oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[i]], boxes[i_interesting].depth_uncertainty[i_durations[i]], color=150, errcolor=150, psym=8
				hline, 0, linestyle=1
				vline, -durations[i]/2*24, linestyle=2
				vline, durations[i]/2*24, linestyle=2
				oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[i_durations[i]], boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[i]],  psym=8, symsize=2
				loadct, 39, /silent
				oploterror, candidates[i,j].depth, candidates[i,j].depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
				if question(interactive=interactive, 'curious?') then stop
			endif
			if not keyword_set(interactive) and i mod 1000 eq 0 then counter, i, n_periods, /timeleft, starttime=starttime, tab_string + tab_string + tab_string+ 'period #'
	
	
		endfor


		squashed_sn = max(dim=2, candidates.depth/candidates.depth_uncertainty)
	
		n_save = 10
		period_peaks = select_peaks(squashed_sn, n_save, /reverse)
		epoch_peaks = lonarr(n_save)
	
		for i=0, n_save-1 do epoch_peaks[i] = min(where(candidates[period_peaks[i],*].depth/candidates[period_peaks[i],*].depth_uncertainty eq squashed_sn[period_peaks[i]]))
	
		best_candidates = candidates[period_peaks, epoch_peaks]	
		best_candidate = best_candidates[0]
		period_peak = period_peaks[0]
		epoch_peak = epoch_peaks[0]
	


			if keyword_set(display) then begin
				cleanplot, /silent
				loadct, 39, /silent
				xplot, 7, title='Phased Search Results Spectrum', xsize=1000, ysize=500
				smultiplot, /init, [2,3], ygap=0.05, xgap=0.01
				smultiplot, /dox
				plot, 1.0/candidates.period, candidates.depth/candidates.depth_uncertainty, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('Phased Transit S/N (\sigma)'), xtick_get=xtick_get, ymargin=[4,4], charsize=1, xmargin=[6,2], yrange=range(candidates.depth/candidates.depth_uncertainty), /nodata
				for k=0, n_elements(candidates[0,*])-1 do oplot, 1.0/candidates[*,k].period, candidates[*,k].depth/candidates[*,k].depth_uncertainty
				axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F5.1)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
				plots, 1/best_candidates.period, best_candidates.depth/best_candidates.depth_uncertainty, color=250, psym=8
				plots, 1/best_candidate.period, best_candidate.depth/best_candidate.depth_uncertainty, color=250, psym=8, symsize=2
	
				smultiplot, /dox
				plot, 1.0/candidates.period, candidates.depth/candidates.depth_uncertainty, xstyle=3, xtitle='Frequency (inverse days)', xtick_get=xtick_get, ymargin=[4,4], charsize=1, xrange=1.0/candidates[[period_peak-100 > 0,period_peak+100 < (n_periods -1)], epoch_peak].period, xmargin=[6,100], yrange=range(candidates.depth/candidates.depth_uncertainty), /nodata
				for k=0, n_elements(candidates[0,*])-1 do oplot, 1.0/candidates[*,k].period, candidates[*,k].depth/candidates[*,k].depth_uncertainty

				axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F6.3)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
				plots, 1/best_candidates.period, best_candidates.depth/best_candidates.depth_uncertainty, color=250, psym=8, noclip=0
				plots, 1/best_candidate.period, best_candidate.depth/best_candidate.depth_uncertainty, color=250, psym=8, symsize=2
	
				i_interesting = where(boxes.n[i_durations[period_peak]] gt 0, n_interesting)
				i_intransit = i_interesting[where_intransit(boxes[i_interesting], best_candidate, n_it, buffer=-best_candidate.duration/4)]
				phased_time = (boxes.hjd - mean(best_candidate.hjd0))/mean(best_candidate.period) + pad + 0.5
				orbit_number = long(phased_time)
				phased_time = (phased_time - orbit_number - 0.5)*mean(best_candidate.period)
	
				i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
				h = histogram(nights[i_intransit], reverse_indices=ri)
				ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
			;	ri_lasts =ri[uniq(ri[0:n_elements(h)-1])+1]-1
				uniq_intransit =(ri[ri_firsts]); + ri[ri_firsts])/2; ri[((ri_firsts +ri_lasts)/2.)]
		
				smultiplot, /dox
				yr = reverse(range(boxes[i_interesting].depth[i_durations[period_peak]], boxes[i_interesting].depth_uncertainty[i_durations[period_peak]]))
				yr = yr < (3*best_candidate.depth)
				yr = yr > (-3*best_candidate.depth)
				loadct, 0, /silent
				ploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[period_peak]], boxes[i_interesting].depth_uncertainty[i_durations[period_peak]], psym=8, yrange=yr, xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata, xr=[-best_candidate.period/2, best_candidate.period/2]*24
				oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[period_peak]], boxes[i_interesting].depth_uncertainty[i_durations[period_peak]], color=150, errcolor=150, psym=8
				hline, 0, linestyle=1
				vline, -durations[period_peak]/2*24, linestyle=2
				vline, durations[period_peak]/2*24, linestyle=2
				oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[i_durations[period_peak]], boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[period_peak]],  psym=8, symsize=2
				loadct, 39, /silent
				oploterror, best_candidate.depth, best_candidate.depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
	
				smultiplot, /dox
				loadct, 0, /silent
				ploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[period_peak]], boxes[i_interesting].depth_uncertainty[i_durations[period_peak]], xr=24*[-durations[period_peak], durations[period_peak]]*3, psym=8, yrange=yr, xtitle='Phased Time (hours)',/nodata
				oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[i_durations[period_peak]], boxes[i_interesting].depth_uncertainty[i_durations[period_peak]], color=150, errcolor=150, psym=8
				hline, 0, linestyle=1
				vline, -durations[period_peak]/2*24, linestyle=2
				vline, durations[period_peak]/2*24, linestyle=2
				oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[i_durations[period_peak]], boxes[i_intransit[uniq_intransit]].depth_uncertainty[i_durations[period_peak]],  psym=8, symsize=2
				loadct, 39, /silent
				oploterror, best_candidate.depth, best_candidate.depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
	
; 				lcs = pdf_to_lc(0)
; 				restore, star_dir + 'cleaned_lc.idl'
; 
; 				i_intransit = where_intransit(cleaned_lc, best_candidate, n_it)
; 				phased_time = (cleaned_lc.hjd - mean(best_candidate.hjd0))/mean(periods[period_peak]) + pad + 0.5
; 				orbit_number = long(phased_time)
; 				phased_time = (phased_time - orbit_number - 0.5)*mean(periods[period_peak])
; 	
; 	
; 				smultiplot
; 				loadct, 0, /silent
; 				plot, 24*phased_time, cleaned_lc.flux, yrange=yr, xtitle='Phased Time (hours)', ytitle='Photometry (mag.)', psym=8, /nodata,xr=[-best_candidate.period/2, best_candidate.period/2]*24
; 				oplot, 24*phased_time, cleaned_lc.flux, psym=8, color=150, symsize=0.7
; 				hline, 0, linestyle=1
; 				vline, -durations[period_peak]/2*24, linestyle=2
; 				vline, durations[period_peak]/2*24, linestyle=2
; 				plots, 24*phased_time[i_intransit], cleaned_lc[i_intransit].flux, psym=8, color=0, symsize=0.7
; 	
; 				smultiplot
; 				loadct, 0, /silent
; 				plot, 24*phased_time, cleaned_lc.flux, yrange=yr, xr=24*[-durations[period_peak], durations[period_peak]]*3, xtitle='Phased Time (hours)', psym=8, /nodata
; 				oplot, 24*phased_time, cleaned_lc.flux, psym=8, color=150, symsize=0.7
; 				hline, 0, linestyle=1
; 				vline, -durations[period_peak]/2*24, linestyle=2
; 				vline, durations[period_peak]/2*24, linestyle=2
; 				plots, 24*phased_time[i_intransit], cleaned_lc[i_intransit].flux, psym=8, color=0, symsize=0.7
; 	
; 	
; 	
	
				smultiplot, /def
			endif

	endfor

		save, filename=star_dir + 'candidates_pdf.idl', best_candidates
		save, filename=star_dir + 'spectrum_pdf.idl', squashed_sn, v_bin, v_min, n_periods
END