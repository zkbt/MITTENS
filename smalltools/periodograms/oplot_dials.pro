PRO oplot_dials, v, f, n_sigma
	theta = findgen(11)/10*2*!pi
	if not keyword_set(n_sigma) then n_sigma = 10
	p = abs(f)^2
	i_peak = peaks(sqrt(p), n_sigma, n_peaks)
	if i_peak[0] ne -1 then begin
		for i=0, n_elements(i_peak)-1 do begin
			phase = atan(imaginary(f[i_peak[i]]), float(f[i_peak[i]]))
			usersym, [0,cos(theta + phase)], [0,sin(theta + phase)], thick=3
			plots, psym=8, v[i_peak[i]], p[i_peak[i]] + max(p)/20, symsize=3, noclip=0
		endfor
	endif
END