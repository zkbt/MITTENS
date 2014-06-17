FUNCTION hemisphere, mo
	common mearth_tools
	if mo_valid(mo) then begin
		north = strmatch(mo, '+')
		if north then return, 'N' else return, 'S'
	endif else mprint, error_string, mo, "doesn't seem to be a real MO string!"
END