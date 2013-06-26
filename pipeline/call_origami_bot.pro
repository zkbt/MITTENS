PRO call_origami_bot
	common this_star
	common mearth_tools

	; avoid unnecesary calls
	if 	is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') and $
		is_uptodate(star_dir() +  'octopus_candidates_pdf.idl', star_dir() + 'box_pdf.idl') then begin
		mprint, skipping_string, 'the origami results appear to be up-to-date; skipping another phased search'
		return
	endif


	if ~file_test(star_dir() + 'octopusinprogress.txt') then begin 
		;make a temporary file to prevent duplication of effort for this long step
		openw, lun, star_dir() + 'octopusinprogress.txt', /get_lun
		spawn, 'hostname', hostname
		printf, lun, hostname
		printf, lun, systime()
		close, lun
		free_lun, lun

		; run origami bot, if possible
		if file_test(star_dir() + 'box_pdf.idl') then begin
			if ~is_uptodate(star_dir + 'boxes_all_durations.txt', star_dir + 'box_pdf.idl') then print_boxes_to_text
			f = file_search(star_dir() +'boxes_all_durations.txt')
			octopusOrigami_path = getenv('MITTENS_PATH') + '/pipeline/speedyfold/octopusOrigami'
			if file_test(octopusOrigami_path) eq 0 then mprint, error_string, " can't find " + octopusOrigami_path + "; check compiling instructions in that directory?"
			mprint, doing_string, 'running octopusOrigami with the following command:'
			mprint, tab_string, octopusOrigami_path + ' ' + f[0]
			for i=0, n_elements(f)-1 do if ~is_uptodate(star_dir +  f[i] +'.bls',star_dir +  f[i]) then spawn, octopusOrigami_path + ' ' + f[i]
			mprint, done_string
		endif else mprint, skipping_string, 'no MarPLES were found for ' + star_dir() + '; skipping origami search'

		origami_to_candidates

		; clean up inprogress file
		file_delete, star_dir() + 'octopusinprogress.txt', /allow
	endif
END




