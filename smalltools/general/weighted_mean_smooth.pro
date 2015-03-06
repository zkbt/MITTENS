FUNCTION weighted_mean_smooth, x, y, y_err, time=time, pause=pause
	if n_elements(x) ne n_elements(y) or n_elements(x) ne n_elements(y_err) or n_elements(y) ne n_elements(y_err) then stop

	smooth_x = x
	smooth_y = y
	smooth_err = y_err
	n = n_elements(x)
	for i=0, n-1 do begin
		i_overlap = where(abs(x - x[i]) le time/2.0, n_overlap)
		if n_overlap gt 1 then begin
			smooth_x[i] = total(x[i_overlap]/y_err[i_overlap]^2)/total(1.0/y_err[i_overlap]^2)
			smooth_y[i] = total(y[i_overlap]/y_err[i_overlap]^2)/total(1.0/y_err[i_overlap]^2)
			smooth_err[i] = sqrt(1.0/total(1.0/y_err[i_overlap]^2))
			chi_sq = total((y[i_overlap] - smooth_y[i])^2/y_err[i_overlap]^2)
			rescaling = sqrt(chi_sq/(n_overlap -1))
			smooth_err[i] *= (rescaling > 1)
		endif
	endfor
	if keyword_set(pause) then stop
	return,struct_conv({x:smooth_x, y:smooth_y, err:smooth_err})
END