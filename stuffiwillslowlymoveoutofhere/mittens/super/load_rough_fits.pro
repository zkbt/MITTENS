FUNCTION load_rough_fits,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n
	sin = 1
	if keyword_set(sin) then suffix = 'roughly_cleaned_toward_sin_lc.idl' else suffix = 'roughly_cleaned_toward_flat_lc.idl'
	if keyword_set(sin) then summary_suffix = 'roughly_toward_sin_summary.idl' else summary_suffix = 'roughly_toward_flat_summary.idl'


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
		restore, star_dir +  'roughly_toward_sin_summary.idl'
		rough_summary_sin = rough_summary
		restore, star_dir +  'roughly_toward_flat_summary.idl'
		rough_summary_flat = rough_summary
		i_sin = where(strmatch(rough_fit.name, 'SIN*'), n_sin)
		if n_sin eq 0 then continue
		i_cos = where(strmatch(rough_fit.name, 'COS*'), n_cos)
		sin_tag = rough_fit[i_sin].name
		split = strsplit(sin_tag, '_')
		period = float(strmid(sin_tag, split[1], split[2] - split[1]-1)) +  float(strmid(sin_tag, split[2], 4))/10000.0
		amp = sqrt(rough_fit[i_sin].coef^2 + rough_fit[i_cos].coef^2)
		this = {ls:ls[i], ye:ye[i], te:te[i], summary_sin:rough_summary_sin,summary_flat:rough_summary_flat, period:period, amp:amp}

		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
;		print_struct, this
	endfor
	return, cloud
END