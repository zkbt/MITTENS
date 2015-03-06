FUNCTION bin_sss, sss, radius, temperature=temperature
	i_radius = where(abs(sss.radius_axis - radius) eq min(abs(sss.radius_axis - radius) ), n_radius_match)
	i_Radius = i_radius[0]
	if keyword_set(temperature) then begin
		if n_radius_match gt 0 then return, sss.temperature_sensitivity[*,i_radius] else return, fltarr(n_elements(sss.period_axis))
	endif else begin
		if n_radius_match gt 0 then return, sss.period_sensitivity[*,i_radius] else return, fltarr(n_elements(sss.period_axis))
	endelse
END