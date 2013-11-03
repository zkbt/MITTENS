PRO flwo_cat, n, str
	lspm = get_lspm_info(n)
	rah = long(lspm.ra/15)
	ram = long((lspm.ra/15 - rah)*60)
	ras = ((lspm.ra/15 - rah)*60 - ram)*60

	decd = long(lspm.dec)
	decm = long((lspm.dec - decd)*60)
	decs = ((lspm.dec - decd)*60-decm)*60

				
	str= 'lspm'+string(form='(I04)', n)+$
		"   " + string(rah, format='(I2)') + ":"+ string(ram, format='(I2)')+ ":"+ string(ras, format='(F4.1)') + $
		'   +'+string(decd, format='(I2)')+ ":"+ string(decm, format='(I2)')+ ":"+ string(decs, format='(F4.1)')+ "   2000.0" + string(form='(F8.2)', lspm.pmra/cos(lspm.dec*!pi/180)/15.0*100.0) + string(form='(F8.2)', lspm.pmdec*100)
	print, str
END