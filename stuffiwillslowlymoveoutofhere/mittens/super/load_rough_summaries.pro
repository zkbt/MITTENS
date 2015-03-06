FUNCTION load_rough_summaries,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n, sin=sin
	if keyword_set(sin) then suffix = 'roughly_toward_sin_summary.idl' else suffix = 'roughly_toward_flat_summary.idl'


	f = subset_of_stars(suffix,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n)

	ls =  long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	i_unknown = where(ls ne 1186 and ls ne 3512 and ls ne 3229 and ls ne 1803, n)
	if n gt 0 then f = f[i_unknown] else stop
	
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(f)

	for i=0, n-1 do begin
	
		star_dir = f[i]
		restore, star_dir + suffix
		this = {ls:ls[i], ye:ye[i], te:te[i], rough:rough_summary}
		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
	
	endfor
	return, cloud
END