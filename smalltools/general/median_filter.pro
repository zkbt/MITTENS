FUNCTION median_filter, t, temp_m, filtering_time=filtering_time;, resmoothing_time


	if not keyword_set(filtering_time) then begin
		@median_filter_parameters
		filtering_time = mf_long_time
		resmoothing_time = mf_short_time
	endif else resmoothing_time = filtering_time/4.0

	m = temp_m - median(temp_m)
	i_nan = where(finite(m, /nan), n_nan)
	if n_nan gt 0 then m[i_nan] = 0.0
	n= n_elements(t)
	;print, ''
	;print, ' MEDIAN FILTER'
	if n_elements(t) ne n_elements(m) then begin
		print, '   $!#%&^| the time and flux values do not match!'
		return, -1
	endif
	;print, '  | the time series contains ', string(n, format='(I4)'), ' points 
	n_iter=5
	splitting_time = filtering_time/2.0;14.0

	splits = 0
	theta = findgen(11)/10*2*!pi
	usersym, cos(theta), sin(theta), /fill
	for i=1l, n-1 do if t[i] - t[i-1] gt splitting_time then splits = [splits, i]
	splits = [splits, n]
	n_splits = n_elements(splits)
	;print, '  | the data have been split into ', string(n_splits-1, format='(I2)'), ' sections separated by >', string(splitting_time, format='(F4.1)'), ' days'
	;print, '  | the median filter has a total width of ', string(filtering_time, format='(F3.1)'), ' days'	
;	plot, t, m, /nodata, xtitle='Time', ytitle='Relative Flux', /yno
	
	for i=0l, n_splits -2 do begin
		t_chunk = t[splits[i]:splits[i+1]-1]
		m_chunk = m[splits[i]:splits[i+1]-1]
		n_chunk = splits[i+1] - splits[i]
		filtered_chunk = fltarr(n_chunk)
		smoothed_chunk = filtered_chunk

		i_okay = indgen(n_chunk)
		for k=0l, n_iter -1 do begin
			t_reflect = [min(t_chunk[i_okay]) - (reverse(t_chunk[i_okay]-min(t_chunk[i_okay]))), t_chunk[i_okay], reverse(t_chunk[i_okay]-max(t_chunk[i_okay])) +max(t_chunk[i_okay])]
			m_reflect = [reverse(m_chunk[i_okay]), m_chunk[i_okay], reverse(m_chunk[i_okay])]
			
			for j=0l, n_chunk-1 do begin
				temp = where(abs(t_reflect - t_chunk[j]) le filtering_time/2.0, n_temp)
				if n_temp gt 0 then filtered_chunk[j] = median(m_reflect[temp])
			endfor
			for j=0l, n_chunk-1 do begin
				smoothed_chunk[j] = mean(filtered_chunk[where(abs(t_chunk - t_chunk[j]) le resmoothing_time/2.0)])
			endfor
;			oplot, color=i*255.0/n_splits, t_chunk, m_chunk, psym=3
;			oplot, color=i*255.0/n_splits, t_chunk,smoothed_chunk
			residuals = m_chunk - smoothed_chunk
			i_okay = where(residuals lt max([3*1.48*median(abs(residuals)), 0.001]), n_okay)
		;	print, n_okay, '/', n_chunk
		endfor
		if n_elements(filtered_all) gt 0 then filtered_all = [filtered_all, residuals] else filtered_all = residuals
	endfor
;	plot, t, m, /yno, psym=8
;	oplot, t, filtered_all, psym=8, symsize=0.5, color=150
	return, filtered_all
END