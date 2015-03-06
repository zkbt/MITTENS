FUNCTION load_good_mjd
	f = file_search('ls*/ye*/te*/good_mjd.idl')
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(f)
	s = create_struct('LSPM', 0, 'TEL', 0, 'YEAR', 0)
	good = dblarr(3000000l)
	count = 0
	for i=0, n-1 do begin
		print, f[i], i, n
		restore, f[i]
		good[count:count + n_elements(good_mjd)-1] = good_mjd
		count += n_elements(good_mjd)	
	endfor
	i_ok = where(good gt 0)
	good = good[i_ok]
	return, good
END