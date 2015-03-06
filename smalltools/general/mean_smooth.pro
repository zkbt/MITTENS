FUNCTION mean_smooth, t, m, filtering_time=filtering_time;, resmoothing_time


	if not keyword_set(filtering_time) then begin
		filtering_time = 0.5
	endif

	n= n_elements(t)
	m_smoothed = fltarr(n)
	if n_elements(t) ne n_elements(m) then begin
		print, '   $!#%&^| the time and flux values do not match!'
		return, -1
	endif
	for i=0, n-1 do m_smoothed[i] = mean(float(m[where(abs(t - t[i]) lt filtering_time/2.0)]), /nan)
	return, m_smoothed
END