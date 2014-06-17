FUNCTION strip_twomass, str
	common mearth_tools
	return,  stregex(/ext, str, mo_regex)

END