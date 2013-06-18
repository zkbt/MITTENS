FUNCTION where_intransit, lc, candidate, n, i_oot=i_oot, buffer=buffer, phased_time=phased_time, pad=pad, boxes=boxes
	if not keyword_set(buffer) then buffer = 0.0
	is_it = bytarr(n_elements(lc))
	i =0 
	if tag_exist(candidate[i], 'PERIOD') then begin
		if n_elements(pad) eq 0 then 	pad = long((max(lc.hjd > candidate.hjd0) - min(lc.hjd < candidate.hjd0))/candidate.period)+1
; pad = long((max(lc.hjd) - min(lc.hjd))/candidate[i].period) + 1
		if n_elements(phased_time) eq 0 then begin
			phased_time = (lc.hjd-candidate[i].hjd0)/candidate[i].period + pad + 0.5
			orbit_number = long(phased_time)
			phased_time = (phased_time - orbit_number - 0.5)*candidate[i].period
		endif
	endif else phased_time = lc.hjd-candidate[i].hjd0
	
	if keyword_set(boxes) then duration = 10.0/24.0/60.0 else duration = candidate[i].duration
	is_it = is_it OR (abs(phased_time) lt (duration/2.0 + buffer))
	i_it = where(is_it, complement=i_oot, n)
	return, i_it
END