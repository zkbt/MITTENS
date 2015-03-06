FUNCTION jxpar, header, tag, n_array, error=error
	error = 0
	; like sxpar, but can handle >1000 repeat entries in headers
	i = where(strmatch(header, tag) or strmatch(header, 'HIERARCH '+tag), n)
	if not keyword_set(n_array) then n_array = n
	if n eq 0 then begin
		print, '      JXPAR + no tag ', tag, " found! returing 0's"
		error = 1
		return, fltarr(n_array)
	endif
	indices = long(stregex(/ext, stregex(/ext, header[i], '.*='), '[0-9]+')) - 1
	values = strarr(n_array)
	values[indices] = stregex(/ext, stregex(/ext, header[i], '=.*'), '[^=].[^/]*') 
	return, values
END