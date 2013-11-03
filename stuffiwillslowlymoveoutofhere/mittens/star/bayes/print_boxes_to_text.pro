PRO print_boxes_to_text
	common this_star
	restore, star_dir() + 'box_pdf.idl'
	
; 	for k=0, n_elements(boxes[0].depth)-1 do begin
; 		filename = star_dir() + 'boxes_'+ string(format='(F4.2)', boxes[0].duration[k])+'days.txt'
; 		simultaneous_filename =  star_dir() + 'boxes_all_durations.txt'
; 		openw, lun, filename, /get_lun
; 		for i=0, n_elements(boxes)-1 do begin
; 			if boxes[i].n[k] gt 0 then begin
; 				str = string(boxes[i].hjd, format='(D12.6)')
; 				str += string(boxes[i].depth[k], format='(F10.5)')
; 				str += string(boxes[i].depth_uncertainty[k], format='(F10.5)')
; 				printf, lun, str
; 			endif
; 		endfor
; 		close, lun
; 		free_lun, lun
; ;		spawn, 'cat ' + filename
; 		print, filename
; 	endfor

	simultaneous_filename =  star_dir() + 'boxes_all_durations.txt'
	openw, simultaneous_lun, simultaneous_filename, /get_lun
	for i=0, n_elements(boxes)-1 do begin
		simultaneous_str = string(boxes[i].hjd, format='(D12.6)')
		for k=0, n_elements(boxes[0].depth)-1 do begin
			simultaneous_str += string(boxes[i].depth[k], format='(F10.5)')
			simultaneous_str += string(boxes[i].depth_uncertainty[k], format='(F10.5)')
		endfor
		simultaneous_str += ' '
		printf, simultaneous_lun, strcompress(simultaneous_str)
	endfor
	close, simultaneous_lun
	free_lun, simultaneous_lun	
END