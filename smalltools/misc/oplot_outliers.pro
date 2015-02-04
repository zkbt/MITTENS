PRO oplot_outliers,flux, scale, color=color,  hjd=hjd
	if not keyword_set(scale) then scale = max(abs(!y.range))

	i_out = where(abs(flux) gt scale, n_out)
	if not keyword_set(color) then color = fltarr(n_elements(flux))
	if n_out gt 0 then begin
		if keyword_set(hjd) then x = hjd[i_out] else x=i_out
		for i=0, n_out-1 do begin
			xyouts, x[i], 0.9*scale*sign(flux[i_out[i]]), string(format='(F5.2)', flux[i_out[i]]), alignment=1.0, color=color[i_out[i]], orientation=90, charthick=1, charsize=0.6*!p.charsize, noclip=0
		endfor
	endif
END
