FUNCTION load_exposures, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n
	; trying to figure out how many pointings we're going to get
	f = subset_of_stars('ext_var.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n)
;	f = f[where(file_test(f + '/astonly.txt'))]
;	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $

	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
 	n = n_elements(f)
	s = create_struct('LS', 0, 'YE', 0, 'TE', 0, 'MJD', 0.0d, 'EXPTIME', 0.0,  'OVERTIME', 0.0,'AST', 0B)
	for i=0, n-1 do begin
		star_dir = f[i]
		print, star_dir
		restore, star_dir + 'raw_ext_var.idl', /rel
		this = replicate(s, n_elements(ext_var))
		this.ls = ls[i]
		this.ye = ye[i]
		this.te = te[i]
		this.mjd = ext_var.mjd_obs
		this.exptime = ext_var.exptime
		this.ast = strmatch(ext_var.styp, '*a*')
		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
	endfor
  return, cloud
END