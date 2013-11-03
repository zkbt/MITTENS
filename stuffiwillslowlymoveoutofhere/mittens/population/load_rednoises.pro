FUNCTION load_rednoises,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n
	f = subset_of_stars('rednoise_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n)
	f = f[where(file_test(f + '/ext_var.idl'))]
	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $
	
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(f)
	s = create_struct('LSPM', 0, {lightcurve}, {external_variable}, 'in_transit', 0B)
	cloud = replicate({redvar:fltarr(9), info:get_lspm_info(0), star_dir:''}, n)
	for i=0, n-1 do begin
	
		star_dir = f[i]
		if total(strmatch(skip_list, star_dir)) then continue
		
			restore, star_dir + 'rednoise_pdf.idl'
			print, star_dir, mean(box_rednoise_variance)
			
			cloud[i].info = get_lspm_info(fix(ls[i]))
			cloud[i].redvar = box_rednoise_variance
			cloud[i].star_dir = star_dir

	endfor
	return, cloud
END