FUNCTION find_best_epoch, boxes, period, duration
	structure_of_a_candidate = {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0}
	best_candidate = structure_of_a_candidate
	mingap = min(boxes[1:*].hjd - boxes.hjd)
	offsetshifts =1.0/60.0/24.0; ((period/2.0 > 1) < 5)/60.0/24.0 	; empirical kuldge
	n_hjd = period/offsetshifts
	hjd = period*dindgen(n_hjd)/n_hjd + min(boxes.hjd)
	sn = fltarr(n_hjd)
	for i=0, n_hjd-1 do begin
		temp_candidate = structure_of_a_candidate
		temp_candidate.period = period
		temp_candidate.duration = duration

		temp_candidate.hjd0 = hjd[i]
		temp_candidate = box_folding_robot(temp_candidate,  boxes, nights=nights, pad=pad, k=k)
		sn[i] = temp_candidate.depth/temp_candidate.depth_uncertainty
		if temp_candidate.depth/temp_candidate.depth_uncertainty gt best_candidate.depth/best_candidate.depth_uncertainty then begin
; 			print_struct, temp_candidate
; 			print, temp_candidate.depth/temp_candidate.depth_uncertainty
			best_candidate = temp_candidate
		endif
		
	endfor
;	print_struct, best_candidate
	peak = select_peaks(sn,1)
	i = where(boxes.n[k] gt 0)
; 	erase
; 	smultiplot, [1,2], /init
; 	smultiplot
; 	xr=range((boxes[i].hjd - min(boxes.hjd)) mod temp_candidate.period)
; 	plot, ((boxes[i].hjd) mod temp_candidate.period) , boxes[i].depth[k]   , xr=xr, xs=3, psym=8
; 	oploterr, ((boxes[i].hjd) mod temp_candidate.period) , boxes[i].depth[k], boxes[i].depth_uncertainty[k], 8
; 	smultiplot
; 	plot, hjd, sn,  color=250, xs=3, xr=xr
; 	smultiplot, /def
	return, best_candidate
END