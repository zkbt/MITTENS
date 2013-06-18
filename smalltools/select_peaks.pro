FUNCTION select_peaks, x, n_peaks, pad=pad, n_sigma=n_sigma, reverse=reverse
	if not keyword_set(n_peaks) then n_peaks=1
	if keyword_set(reverse) then temp = reverse(x) else temp = x
	peaks = lonarr(n_peaks)
	if not keyword_set(pad) then pad = 10
	for i=0, n_peaks-1 do begin
		j = where(temp eq max(temp), n)
		peaks[i] = j[0]
		i_nearby = indgen(2*pad) + j[0] - pad
		gauss = mpfitpeak(i_nearby, temp[i_nearby], fit)
		sigma = uint(fit[2]) > 1
		;add this - estimate width of line, quintuple it, ignore
		if not keyword_set(n_sigma) then n_sigma = 5
		temp[peaks[i] - n_sigma*sigma > 0:peaks[i]+n_sigma*sigma < (n_elements(temp)-1)] =  0
	endfor
	if keyword_set(reverse) then return, n_elements(temp)-peaks-1 else return, peaks
END