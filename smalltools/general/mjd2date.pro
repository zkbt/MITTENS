PRO mjd2date, mjd
	jd = mjd + 2400000.5d
	caldat, jd, month, day, year, hour, minute, second
	print, mjd, ' = ', strcompress(/remove_all,year), '.', strcompress(/remove_all,month), '.', strcompress(/remove_all, day)
END