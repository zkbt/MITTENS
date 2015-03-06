FUNCTION get_blob
	spawn, 'ls nights/t*/*.idl', previously_done
	restore, previously_done[0]
	blob= tel_night.obs
	for i=1, n_elements(previously_done)-1 do begin 
		restore, previously_done[i]
		blob = [blob,tel_night.obs]
	endfor
	return, blob
END