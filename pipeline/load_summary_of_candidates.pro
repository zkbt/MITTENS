PRO load_summary_of_candidates, summary_of_candidates

	common mearth_tools
	f = file_search('ls*/combined/octopus_candidates_pdf.idl')

;	f = subset_of_stars(filename,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, combined=combined) + filename
; 	if keyword_set(unknown) then begin
; 		ls =  long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
; 		i_unknown = where(ls ne 1186 and ls ne 3512 and ls ne 3229 and ls ne 1803, n)
; 		if n gt 0 then f = f[i_unknown] else stop
; 	endif
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	n = n_elements(f)
	template = create_struct('LS', 0l, 'STAR_DIR', '', {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, ratio:0.0, n_boxes:0, n_points:0, rescaling:1.0, ignore:0B, known:0B, variability:0B, stats:{boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}} )
	summary_of_candidates = replicate(template, n)
	has_boxes = bytarr(n)
	mprint, doing_string, 'making a summary of the candidates; saving to population/summary_of_candidates.idl'
	for i=0, n-1 do begin
		s = template
		restore, f[i]
		star_dir = stregex(f[i], /ext, 'ls[0-9]+/(ye[0-9]+|combined)/((te[0-9]+|combined)/)?');stregex(f[i], /ext, 'ls[0-9]+/(ye[0-9]+/te[0-9]+|combined)') +'/'
		copy_struct, best_candidates[0], s
		has_boxes[i]= file_test(star_dir + 'box_pdf.idl')
		
		if file_test(star_dir + 'comments.log') then begin
			comments = ''
			openr, lun, /get_lun, star_dir + 'comments.log'
			while eof(lun) eq 0 do begin
				readf, lun, comments
				if strmatch(comments, '*IGNORE*', /fold_case) then s.ignore = 1
				if strmatch(comments, '*VARIAB*', /fold_case) then s.variability = 1
				if strmatch(comments, '*KNOWN*', /fold_case) then s.known = 1
			endwhile
			close, lun
			free_lun, lun
		endif
		summary_of_candidates[i] = s
		summary_of_candidates[i].star_dir = star_dir
		summary_of_candidates[i].ls = ls[i]
		if file_test(star_dir + 'box_pdf.idl') then begin
		;	if ~file_test( star_dir + 'octopus_stat_summary.idl') then begin
				restore, star_dir + 'box_pdf.idl'
				stats = {boxes:fltarr(9), points:0, points_per_box:fltarr(9), start:0.0d, finish:0.0d, periods_searched:0L}
				stats.boxes[*] = total(boxes.n[*] gt 0, 2)
				stats.points_per_box =  total(boxes.n[*], 2)/ total(boxes.n[*] gt 0, 2)
				restore, star_dir + 'inflated_lc.idl'
				stats.points = n_elements(inflated_lc)
				stats.start = min(inflated_lc.hjd)
				stats.finish = max(inflated_lc.hjd)
				stats.periods_searched = file_lines(star_dir() + 'boxes_all_durations.txt.bls')
				save,filename=star_dir + 'octopus_stat_summary.idl', stats
		;	endif
			restore, star_dir + 'octopus_stat_summary.idl'
			summary_of_candidates[i].stats = stats
		endif
		mprint, tab_string, star_dir
	endfor  
	summary_of_candidates = summary_of_candidates[where(has_boxes)]
	save, summary_of_candidates, filename='population/summary_of_candidates.idl'

END
