FUNCTION mearth_timezone
	common mearth_tools
	common this_star
	if strmatch(star_dir, '*te1*') then timezone = 5.0/24.0 ; in hours west!
	if strmatch(star_dir, '*te0*') then timezone = 7.0/24.0
	if strmatch(star_dir, '*combined*') then begin
		;mprint, tab_string, tab_string, 'using MEarth Average Timezone (MAT = -6hrs)'
		timezone = 6.0/24
	endif
	if n_elements(timezone) eq 0 then begin
		mprint, tab_string, error_string, "mearth_timezone.pro can't seem to figure out what timezone is needed for ", star_dir
		stop
	endif
;	other_tel = ~(strmatch(star_dir, '*te0*') or strmatch(star_dir, '*combined*')) 
;	if other_tel then begin
;		if strmatch(star_dir, '*te11*') then timezone = 0.0/24.0
;		if strmatch(star_dir, '*te12*') then timezone = -1.0/24.0
;	endif else timezone = 7.0/24.0
	return, timezone
END