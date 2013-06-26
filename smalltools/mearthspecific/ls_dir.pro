FUNCTION ls_dir
	common this_star
	ls_dir = stregex(star_dir(), 'ls[0-9]+', /ext) + '/'
	return, ls_dir
END