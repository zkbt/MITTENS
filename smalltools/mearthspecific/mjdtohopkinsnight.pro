FUNCTION mjdtohopkinsnight, mjd
	instantaneous_arizona_jd = mjd+2400000.5d - mearth_timezone()
	dayofsunset_arizona_jd = mjd+2400000.5d - mearth_timezone() - 0.5

	caldat, dayofsunset_arizona_jd, month, day, year, d, e, f
	str = string(form='(I04)', year) + string(form='(I02)', month) + string(form='(I02)', day) 
	return, str
END