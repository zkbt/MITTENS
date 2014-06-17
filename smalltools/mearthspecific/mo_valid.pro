FUNCTION mo_valid, mo
	attempted_mo = strip_twomass(mo)
	return, strlen(attempted_mo) eq 16 
END