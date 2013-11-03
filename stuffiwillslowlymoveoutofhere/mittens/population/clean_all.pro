PRO clean_all
	common mearth_tools
	subset = subset_of_stars('candidates_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n) + 'candidates_pdf.idl'
	ls = long(stregex(/ext, stregex(/ext, subset, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, subset, 'te[0-9]+'), '[0-9]+'))
	

	which = 0
	for i=0, n_elements(subset)-1 do begin
		set_star, ls[i], ye[i], te[i]
		restore, star_dir() + 'candidates_pdf.idl'
		lcs = pdf_to_lc(best_candidates[which])
	endfor
END
	