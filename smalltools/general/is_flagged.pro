FUNCTION is_flagged, test, flags, print_result=print_result
	for i =0, n_elements(flags)-1 do begin
		this_flag = (test/flags[i] mod 2 gt 0)
		if keyword_set(print_result) then print, '     ', string(total(this_flag), format='(I)'), ' flagged with flag ', flags[i]
		if i eq 0 then flagged = this_flag else flagged += this_flag
	endfor
	return, flagged
END
