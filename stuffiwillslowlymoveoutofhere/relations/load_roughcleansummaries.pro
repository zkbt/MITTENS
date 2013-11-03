FUNCTION load_roughcleansummaries, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, sin=sin
	; trying to figure out how many pointings we're going to get
	if keyword_set(sin) then filename = 'roughly_toward_sin_summary.idl' else filename = 'roughly_toward_flat_summary.idl'
	f = subset_of_stars(filename,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n)
;	f = f[where(file_test(f + '/astonly.txt'))]
;	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $

	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
 	n = n_elements(f)
	
	for i=0, n-1 do begin
		star_dir = f[i]
		print, star_dir
		restore, star_dir + filename
		if i eq 0 then	this = create_struct('LS', 0, 'YE', 0, 'TE', 0, 'ROUGH', rough_summary)
		
		this.ls = ls[i]
		this.ye = ye[i]
		this.te = te[i]
		this.rough = rough_summary
		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
	endfor

  	return, cloud
END