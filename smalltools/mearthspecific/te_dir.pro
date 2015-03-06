FUNCTION te_dir
	common this_star
	te_dir = stregex(star_dir(), 'te[0-9]+', /ext) + '/'
	return, te_dir
END