FUNCTION is_astonly
	common this_star
	return, file_test(star_dir + 'astonly.txt')
END