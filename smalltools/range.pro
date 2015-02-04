FUNCTION range, y, y_uncertainty
	if keyword_set(y_uncertainty) then return, [min(y - y_uncertainty), max(y+y_uncertainty)] else return, [min(y), max(y)]
END