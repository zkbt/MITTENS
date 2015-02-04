FUNCTION mjdtodate, mjd
	jd = mjd + 2400000.5d
	caldat, jd, month, day, year, hour, minute, second
	return, strcompress(/remove_all,year) + '.'+ strcompress(/remove_all,month)+ '.'+ strcompress(/remove_all, day)
END