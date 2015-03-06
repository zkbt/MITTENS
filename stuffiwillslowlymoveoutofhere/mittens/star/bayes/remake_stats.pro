PRO remake_stats, combined=combined, year=year, lspm=lspm
	common mearth_tools
	subset = subset_of_stars('candidates_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, combined=combined) + 'candidates_pdf.idl'
	ls = long(stregex(/ext, stregex(/ext, subset, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, subset, 'te[0-9]+'), '[0-9]+'))

	which = 0
	for i=0, n_elements(subset)-1 do begin
		set_star, ls[i], ye[i], te[i], combine=combined
		candidate_filename =  'candidates_pdf.idl'
		if file_test(star_dir() + candidate_filename) and file_test(star_dir() + 'box_pdf.idl') then begin
			restore, star_dir() + candidate_filename
			restore, star_dir() + 'box_pdf.idl'
			stats = {boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}
			stats.boxes[*] = total(boxes.n[*] gt 0, 2)
			stats.points_per_box =  total(boxes.n[*], 2)/ total(boxes.n[*] gt 0, 2)
			restore, star_dir() + 'inflated_lc.idl'
			stats.points = n_elements(inflated_lc)
			stats.start = min(inflated_lc.hjd)
			stats.finish = max(inflated_lc.hjd)
			restore, star_dir() + 'spectrum_pdf.idl'
			stats.periods_searched = long(n_periods)
			save,filename=star_dir() + 'stat_summary.idl', stats
		endif
		candidate_filename =  'octopus_candidates_pdf.idl'
		if file_test(star_dir() + candidate_filename) and file_test(star_dir() + 'box_pdf.idl') then begin
			restore, star_dir() + candidate_filename
			restore, star_dir() + 'box_pdf.idl'
			stats = {boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}
			stats.boxes[*] = total(boxes.n[*] gt 0, 2)
			stats.points_per_box =  total(boxes.n[*], 2)/ total(boxes.n[*] gt 0, 2)
			restore, star_dir() + 'inflated_lc.idl'
			stats.points = n_elements(inflated_lc)
			stats.start = min(inflated_lc.hjd)
			stats.finish = max(inflated_lc.hjd)
			stats.periods_searched = file_lines(star_dir() + 'boxes_all_durations.txt.bls')
			save,filename=star_dir() + 'octopus_stat_summary.idl', stats
		endif

	endfor
END
	