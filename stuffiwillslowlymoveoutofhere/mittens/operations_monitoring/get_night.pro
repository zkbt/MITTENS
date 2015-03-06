PRO get_night, date, tel
	dir = '/pool/barney0/mearth/lightcurves/'
	date_string = string(date, format='(I8)')
	command = 'ls -R' + dir + '*	
END
