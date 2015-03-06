FUNCTION interpolate_sensitivity, periodlikeaxis, radius, sensitivity=sensitivity, temperature=temperature
	common mearth_tools
	if keyword_set(temperature) then begin
		i_which = where(strmatch(tag_names(sensitivity), 'TEM*'), n_match)
	endif else begin
		i_which = where(strmatch(tag_names(sensitivity), 'PER*'), n_match)
	endelse
	x = interpol(findgen(n_elements(sensitivity.(i_which).detection[*,0])), sensitivity.(i_which).grid, periodlikeaxis)
	y = interpol(findgen(n_elements(sensitivity.(i_which).detection[0,*])), sensitivity.radii, radius)

	return, interpolate(sensitivity.(i_which).detection, x, y)*(radius ge min(sensitivity.radii))
END
