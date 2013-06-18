PRO call_origami_bot
	common this_star
	if file_test(star_dir() + 'box_pdf.idl') then begin
		if ~is_uptodate(star_dir + 'boxes_all_durations.txt', star_dir + 'box_pdf.idl') then print_boxes_to_text
		f = file_search(star_dir() +'boxes_all_durations.txt')
		octopusOrigami_path = getenv('MITTENS_PATH') + '/pipeline/speedyfold/octopusOrigami'
		if file_test(octopusOrigami_path) eq 0 then mprint, error_string, " can't find " + octopusOrigami_path + "; check compiling instructions in that directory?"
		print,  octopusOrigami_path + ' ' + f[0]
		for i=0, n_elements(f)-1 do if ~is_uptodate(star_dir +  f[i] +'.bls',star_dir +  f[i]) then spawn, octopusOrigami_path + ' ' + f[i]
	endif
	origami_to_candidates
END




