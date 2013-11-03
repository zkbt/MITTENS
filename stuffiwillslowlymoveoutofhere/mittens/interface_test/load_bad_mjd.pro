FUNCTION load_bad_mjd
	f = file_search('ls*/ye*/te*/bad_mjd.idl')
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(f)
	s = create_struct('LSPM', 0, 'TEL', 0, 'YEAR', 0)
	bad = dblarr(3000000l)
	count = 0
	for i=0, n-1 do begin
		print, f[i], i, n
		restore, f[i]
		bad[count:count + n_elements(bad_mjd)-1] = bad_mjd
		count += n_elements(bad_mjd)	
	endfor
	i_ok = where(bad gt 0)
	bad = bad[i_ok]
	return, bad
END