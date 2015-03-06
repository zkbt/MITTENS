FUNCTION sigma_clip_zero, x
	xx = x
		sigma = stddev(xx, /nan)
		n_clip = 100
		while(n_clip gt 0) do begin
			to_clip = where(abs(xx - mean(xx, /nan))/sigma gt 5 or finite(/nan, sign=0, xx) ne 0, n_clip)
			if n_clip gt 0 then xx[to_clip] = mean(xx, /nan)
		endwhile
	return, xx - mean(xx)
END