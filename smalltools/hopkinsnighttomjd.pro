FUNCTION hopkinsnighttomjd, input_night

	night = long(input_night)
	year = night/10000L
	month = (night mod 10000)/100L
	day = (night mod 100)

	jul = julday(month, day, year)
	mjd = jul - 2400000.5d + mearth_timezone() + 0.5

	return, mjd	
END