PRO test_box_align
	common mearth_tools
	common this_star
	@filter_parameters
	@psym_circle
	; load up files
	if n_elements(candidate) eq 0 then begin
		; prompt for which candidate to explore!
		restore, star_dir + 'candidates_pdf.idl'
		print_struct, best_candidates
		if not keyword_set(which) then which = question(/number, /int, 'which candidate would you like to explore?')
		candidate = best_candidates[which]	
	endif

	; load up (this season of) this star
	restore, star_dir + 'box_pdf.idl'
	restore, star_dir + 'cleaned_lc.idl'

	interactive, /on
	display, /on
	cleanplot
	xplot
          if n_elements(k) eq 0 then begin
            duration_bin =(boxes[0].duration[1]  - boxes[0].duration[0])  ;requires linear spacing of durations!
            k = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)  
          endif
          if n_elements(pad) eq 0 then 	pad = long((max(boxes.hjd) - min(boxes.hjd))/0.5)+1
		if n_elements(nights) eq 0 then  	nights = round(boxes.hjd -timezone)

          ; only look at non-empty boxes
          i_interesting = where(boxes.n[k] gt 0, n_interesting)
          ; find in-transit points (N.B. uses smoothly varying duration, not blocky grid)
          phased_time = (boxes.hjd - candidate.hjd0)/candidate.period +  pad+ 0.5
          orbit_number = long(phased_time)
          phased_time = (phased_time - orbit_number - 0.5)*candidate.period
          i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidate, n_it, /boxes, phased_time=phased_time[i_interesting], pad=pad)];buffer=-candidate.duration/4,
      
          ; sort in-transit points by their distance from mid-transit
          i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
          ; pull out the closest box on each unique night
          h = histogram(nights[i_intransit], reverse_indices=ri)
          ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
          uniq_intransit =ri[ri_firsts]


           ploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k], xr=24*[-candidate.duration, candidate.duration]*3, psym=8, yrange=reverse(range(boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k])), xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata
            oploterror, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k], color=150, errcolor=150, psym=8
            hline, 0, linestyle=1
            vline, -candidate.duration/2*24, linestyle=2
            vline, candidate.duration/2*24, linestyle=2
            oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k],  psym=8, symsize=2
            loadct, 39, /silent
            oploterror, candidate.depth, candidate.depth_uncertainty, psym=3, symsize=2, color=250, errcolor=250, thick=3
 




	lc = cleaned_lc
	pad = long((max(lc.hjd) - min(lc.hjd))/candidate.period) + 1
	lc_phased_time = (lc.hjd-candidate.hjd0)/candidate.period + pad + 0.5
	orbit_number = long(lc_phased_time)
	lc_phased_time = (lc_phased_time - orbit_number - 0.5)*candidate.period

	@psym_circle
	usersym , cos(theta), sin(theta)
	oplot, psym=8, lc_phased_time*24, cleaned_lc.flux

	for i=0, n_elements(boxes)-1 do begin
		i_this = where(abs(lc.hjd - boxes[i].hjd) lt candidate.duration/2.0, n)
		if n gt 0 then for j=0, n-1 do plots, [lc_phased_time[i_this[j]], phased_time[i]]*24, [lc[i_this[j]].flux, boxes[i].depth[k]]

	endfor
		stop

END