FUNCTION generate_boxes, lc , highres=highres, durations=durations, res=res
;+
; NAME:
;	generate_boxes
; PURPOSE:
;	generate season-long boxes to be used in a Bayesian light curve characterization scheme
; CALLING SEQUENCE:
;	  boxes = generate_boxes()
; INPUTS:
; 
; KEYWORD PARAMETERS:
; 
; OUTPUTS:
;	
; RESTRICTIONS:
; 
; EXAMPLE:
; 
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-

	; setup environment
; 	common this_star
; 	common mearth_tools
	@data_quality
	@filter_parameters

	if ~keyword_set(durations) then begin
		min_duration = 0.02
		max_duration = 0.1
		bin_duration = 0.01
		n_durations = (max_duration - min_duration)/bin_duration+1;10
		durations = findgen(n_durations)*bin_duration + min_duration
	endif else begin
		max_duration = max(durations)
		n_durations = n_elements(durations)
	endelse
	if ~keyword_set(res) then res = 5.0/60.0/24.0; 10./60./24.
	if keyword_set(highres) then res = 2.0/60.0/24.0

	i_okay = where(lc.okay, n_okay)
	t = lc[i_okay].hjd
	dt = t[1:*] - t[0:*]
	span = max(t) - min(t)
	
	grid = min(floor(t-1)) + dindgen((span + 3)/res)*res

	h = histogram(t + res/2.0, binsize=res, min=min(floor(t-1)), max=max(t)+1, locations=locations)
	smoothed_h = smooth(float(h), round(max_duration/res)+1)
; 	plot, locations, h
; 	oplot, locations, smoothed_h

	i_full = where(smoothed_h gt 0, n_full)
	if n_full eq 0 then stop
	fine = locations[i_full]

; 	starts_of_gaps = [where(dt gt max_duration), n_elements(t)-1]
; 	if starts_of_gaps[0] eq -1 then starts_of_gaps = n_elements(t)-1
; 	ends_of_gaps = [0, where(dt gt max_duration)+1]
; 	for i=0, n_elements(starts_of_gaps)-1 do begin
; 		chunk_start = t[ends_of_gaps[i]] - max_duration/2.0 - res
; 		chunk_end = t[starts_of_gaps[i]] + max_duration/2.0 + res
; 		chunk_n = (chunk_end - chunk_start)/res
; 		chunk = dindgen(chunk_n)*res + chunk_start
; 		if n_elements(fine) eq 0 then fine = chunk else fine = [fine, chunk]
; 	endfor

;  	xplot, xsize=2000, ysize=300
; 	plot, t - min(t), ones(n_elements(t))+0.05, psym=-8, yr=[.9, 1.1], xr=[0,4]
; 	oplot, fine - min(t), ones(n_elements(fine))-0.05, psym=-4
	

	one_box = {hjd:0.0d, duration:durations, depth:fltarr(n_durations), depth_uncertainty:fltarr(n_durations)-1, n:intarr(n_durations), rescaling:fltarr(n_durations)}
	boxes = replicate(one_box, n_elements(fine))
	boxes.hjd = fine
	
	return, boxes
END