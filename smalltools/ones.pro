FUNCTION ones, a, b, c
	if keyword_set(c) then return, fltarr(a, b, c) + 1.0
	if keyword_set(b) then return, fltarr(a, b) + 1.0
	if keyword_set(a) then return, fltarr(a) + 1.0
	return, 1.0
END