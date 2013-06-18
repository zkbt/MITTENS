FUNCTION generate_grazers, lc
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
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	max_duration = 0.2
	n_durations = 10
	
	res = 10./60./24.

	t = lc.hjd
	dt = t[1:*] - t[0:*]
	starts_of_gaps = [where(dt gt max_duration), n_elements(t)-1]
	if starts_of_gaps[0] eq -1 then starts_of_gaps = n_elements(t)-1

	ends_of_gaps = [0, where(dt gt max_duration)+1]
	for i=0, n_elements(starts_of_gaps)-1 do begin
		chunk_start = t[ends_of_gaps[i]] - max_duration/2.0
		chunk_end = t[starts_of_gaps[i]] + max_duration/2.0
		chunk_n = (chunk_end - chunk_start)/res
		chunk = dindgen(chunk_n)*res + chunk_start
		if n_elements(fine) eq 0 then fine = chunk else fine = [fine, chunk]
	endfor

;  	xplot, xsize=2000, ysize=300
; 	plot, t - min(t), ones(n_elements(t))+0.05, psym=-8, yr=[.9, 1.1], xr=[0,4]
; 	oplot, fine - min(t), ones(n_elements(fine))-0.05, psym=-4
	

	one_box = {hjd:0.0d, duration:(findgen(n_durations)+1)*max_duration/n_durations, depth:fltarr(n_durations), depth_uncertainty:fltarr(n_durations)-1, n:intarr(n_durations)}
	boxes = replicate(one_box, n_elements(fine))
	boxes.hjd = fine
	
	return, boxes
END