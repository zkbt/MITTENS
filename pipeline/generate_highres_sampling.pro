FUNCTION generate_highres_sampling, lc, box=box
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

	max_duration = 0.1
	res = 0.5/60./24.
	if keyword_set(highres) then res = 2.0/60.0/24.0

	t = lc.hjd
	dt = t[1:*] - t[0:*]
	if keyword_set(box) then begin
		t = [lc.hjd, box.hjd - box.duration/2.001 + median(dt),  box.hjd + box.duration/2.001 - median(dt)]
		t = t[sort(t)]
	endif
	dt = t[1:*] - t[0:*]

	starts_of_gaps = [where(dt gt max_duration), n_elements(t)-1]
	if starts_of_gaps[0] eq -1 then starts_of_gaps = n_elements(t)-1
	ends_of_gaps = [0, where(dt gt max_duration)+1]
	for i=0, n_elements(starts_of_gaps)-1 do begin
		chunk_start = t[ends_of_gaps[i]] - median(dt)/2.0;res
		chunk_end = t[starts_of_gaps[i]] + median(dt)/2.0;res
		chunk_n = (chunk_end - chunk_start)/res > 1
		chunk = dindgen(chunk_n)*res + chunk_start
		if n_elements(fine) eq 0 then fine = chunk else fine = [fine, chunk]
	endfor

	return, fine
END