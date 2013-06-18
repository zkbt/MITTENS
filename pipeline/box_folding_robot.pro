FUNCTION box_folding_robot, input_candidate, boxes, nights=nights, pad=pad, k=k

          common mearth_tools
		
          
          ; don't modify the input_candidate
          candidate = input_candidate
          
          if n_elements(k) eq 0 then begin
            duration_bin =(boxes[0].duration[1]  - boxes[0].duration[0])  ;requires linear spacing of durations!
            k = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)  
          endif
        if n_elements(pad) eq 0 then 	pad = long((max(boxes.hjd) - min(boxes.hjd))/0.5)+1
	if n_elements(nights) eq 0 then  begin
		@filter_parameters
		nights = round(boxes.hjd -mearth_timezone())
	endif

          ; only look at non-empty boxes
          i_interesting = where(boxes.n[k] gt 0, n_interesting)
          ; find in-transit points (N.B. uses smoothly varying duration, not blocky grid)
;           phased_time = (boxes.hjd - candidate.hjd0)/candidate.period +  pad+ 0.5
;           orbit_number = long(phased_time)
;           phased_time = (phased_time - orbit_number - 0.5)*candidate.period

	phased_time = (boxes.hjd - candidate.hjd0)/candidate.period mod 1.0
	i_under = where(phased_time lt -0.5, n_under)
	if n_under gt 0 then phased_time[i_under] +=1
	i_over = where(phased_time gt 0.5, n_over)
	if n_over gt 0 then phased_time[i_over] -=1
	phased_time *= candidate.period
	mingap = min(boxes[1:*].hjd - boxes.hjd)
	i_int1 = where(abs(phased_time[i_interesting]) lt mingap/2.0, n_it)
	;  i_int1 = where_intransit(boxes[i_interesting], candidate, n_it, /boxes, phased_time=phased_time[i_interesting], pad=pad)
	if n_it gt 0 then begin
          i_intransit = i_interesting[i_int1];buffer=-candidate.duration/4,
      	uniq_intransit = indgen(n_elements(i_intransit))
;           ; sort in-transit points by their distance from mid-transit
;           i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
;           ; pull out the closest box on each unique night
;           h = histogram(nights[i_intransit], reverse_indices=ri)
;           ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
;           uniq_intransit =ri[ri_firsts]
;     
          ; calculate depth and first uncertainty for box
          candidate.depth = total(boxes[i_intransit[uniq_intransit]].depth[k]/boxes[i_intransit[uniq_intransit]].depth_uncertainty[k]^2)/$
                          total(1.0/boxes[i_intransit[uniq_intransit]].depth_uncertainty[k]^2)
          candidate.depth_uncertainty = 1.0/$
                          sqrt(total(1.0/boxes[i_intransit[uniq_intransit]].depth_uncertainty[k]^2))
          ; record some diagnostics about the candidate
          candidate.n_boxes = n_elements(uniq_intransit)
          candidate.n_points = total(boxes[i_intransit[uniq_intransit]].n[k], /int)
          ; estimate the chi^2 of the candidate, given the boxes involved
          chi_sq = total(((boxes[i_intransit[uniq_intransit]].depth[k] - candidate.depth)/boxes[i_intransit[uniq_intransit]].depth_uncertainty[k])^2)
          ; check if chi^2 is too high and the uncertainty needs to be rescaled
          if candidate.n_boxes gt 1 then begin    
            candidate.rescaling =  sqrt((chi_sq/(candidate.n_boxes -1) > 1.0))
            candidate.depth_uncertainty *= candidate.rescaling
          endif
    
	endif
          if keyword_set(display) and keyword_set(interactive) then begin
	!p.multi=[0,1,2]
            loadct, 0, /silent
            plot, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], xr=24*[-candidate.duration, candidate.duration]*3, psym=8, yrange=reverse(range(boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k])), xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata
		!p.color=150
            oploterr, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k],8
		!p.color=0
            hline, 0, linestyle=1
            vline, -candidate.duration/2*24, linestyle=2
            vline, candidate.duration/2*24, linestyle=2
	if n_elements(i_intransit) gt 0 then begin
	!p.thick=3
            oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k],  psym=8
            loadct, 39, /silent
	!p.thick=1	
	!p.color=250

            oploterror, candidate.depth, candidate.depth_uncertainty, psym=3, thick=5, errcolor=250
	!p.color=0 
	endif
            loadct, 0, /silent
            plot, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], xr=24*[-0.5,0.5]*candidate.period, psym=8, yrange=reverse(range(boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k])), xtitle='Phased Time (hours)', ytitle='Box Depth (mag.)', /nodata
		!p.color=150
            oploterr, 24*phased_time[i_interesting], boxes[i_interesting].depth[k], boxes[i_interesting].depth_uncertainty[k],8
		!p.color=0
            hline, 0, linestyle=1
            vline, -candidate.duration/2*24, linestyle=2
            vline, candidate.duration/2*24, linestyle=2
	if n_elements(i_intransit) gt 0 then begin
	!p.thick=3
            oploterror, 24*phased_time[i_intransit[uniq_intransit]], boxes[i_intransit[uniq_intransit]].depth[k], boxes[i_intransit[uniq_intransit]].depth_uncertainty[k],  psym=8
            loadct, 39, /silent
	!p.thick=1	
	!p.color=250

            oploterror, candidate.depth, candidate.depth_uncertainty, psym=3, thick=5, errcolor=250
	!p.color=0 

	endif
;	print, n_elements(uniq_intransit)
;	print_struct, candidate
           if question(interactive=interactive, 'curious?') then stop
          endif
;           print, candidate.period, candidate.hjd0, candidate.duration, format='(D,D,D)'
; 	print, boxes[0].duration[k]
; stop
          return, candidate
END
