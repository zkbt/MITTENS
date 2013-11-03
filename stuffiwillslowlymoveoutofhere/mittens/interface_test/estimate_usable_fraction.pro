FUNCTION estimate_usable_fraction
	good = round(load_good_mjd() - mearth_timezone())
	bad = round(load_bad_mjd()- mearth_timezone())
	r = range([good,bad])
	n = r[1] - r[0]


	h_all = histogram([bad,good] - mearth_timezone(), min=r[0], max=r[1])
	h_good = histogram([good - mearth_timezone()], min=r[0], max=r[1])
	h_bad = histogram([bad - mearth_timezone()], min=r[0], max=r[1], loc=loc)
	usable_fraction = float(h_bad)/h_all
	cleanplot, /sil
	loadct, 39
	xplot, xsize=2000, ysize=500
	plot, loc, usable_fraction, psym=8, xtitle='MJD', ytitle='Fraction of Images Used from Night', xs=3

	return, {night:loc, usable_fraction:usable_fraction}
END