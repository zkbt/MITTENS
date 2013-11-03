FUNCTION probability_duration_is_okay, period_grid, duration_grid, shhh=shhh
	common this_star
	common mearth_tools
	if ~keyword_set(shhh) then begin
		mprint, tab_string + tab_string, doing_string, 'placing duration constraints on possible candidates,'
		mprint, tab_string + tab_string + tab_string, 'assuming stellar (mass, radius) = (', string(form='(F4.2)', lspm_info.mass),',', string(form='(F4.2)',lspm_info.radius), ') solar' 
	endif
	tmax = period_grid/!pi*asin(1.0/a_over_rs(lspm_info.mass, lspm_info.radius, period_grid))
	width = 0.3*tmax
	prob = exp(-0.5*(duration_grid - tmax)^2/width^2)
	;prob /= max(prob)
	prob = prob > (duration_grid LT tmax)
	return, prob
END