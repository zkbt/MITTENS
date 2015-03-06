FUNCTION ls_dir
	common this_star
	ls_dir = stregex(star_dir(), 'ls[0-9]+', /ext) + '/'
 	print. "HOPEFULLY ls_dir.pro ISN'T CALLED ANYMORE!"
	stop
	return, ls_dir
END