FUNCTION mearth_timezone
	common mearth_tools
	common this_star
	other_tel = ~(strmatch(star_dir, '*te0*') or strmatch(star_dir, '*combined*')) 
	if other_tel then begin
		if strmatch(star_dir, '*te11*') then timezone = 0.0/24.0
		if strmatch(star_dir, '*te12*') then timezone = -1.0/24.0
	endif else timezone = 7.0/24.0
	return, timezone
END