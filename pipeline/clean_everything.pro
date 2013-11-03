PRO clean_everything
	common mearth_tools
	f = file_search('ls*/combined/', /mark_dir)
	for i=0, n_elements(f)-1 do begin
		set_star, f[i]
		if file_test(star_dir() + 'box_pdf.idl') eq 0 then continue
		if is_uptodate(star_dir() + 'cleaned_lc.idl', star_dir() + 'box_pdf.idl') then continue
		nothing  = {period:1d8, hjd0:0.0d, duration:0.02, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0, inflation_for_bad_duration:1.0}
		process_with_candidate, nothing
	endfor
END