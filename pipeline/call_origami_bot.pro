PRO call_origami_bot, bulldoze=bulldoze
	common this_star
	common mearth_tools


	;if systime(/jul) gt 2456673.1 + 50 then stop
	; NEED TO SWTICH FILENAMES FOR OCTOPUS_CANDIDATES_PDF.IDL"

	; avoid unnecesary calls
	if 	is_uptodate(star_dir() + 'boxes_all_durations.txt.bls', star_dir() + 'box_pdf.idl') and $
		is_uptodate(star_dir() + typical_candidate_filename, star_dir() + 'box_pdf.idl') then begin
		mprint, skipping_string, 'the origami results appear to be up-to-date; skipping another phased search'
		return
	endif

	if keyword_set(bulldoze) then file_delete, star_dir() + 'octopusinprogress.txt', /allow
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

			if ~is_uptodate(star_dir() + 'boxes_all_durations.txt', star_dir() + 'box_pdf.idl') then print_boxes_to_text
			f = file_search(star_dir() +'boxes_all_durations.txt')
			octopusOrigami_path = getenv('MITTENS_PATH') + '/pipeline/speedyfold/octopusOrigami'
			if file_test(octopusOrigami_path) eq 0 then mprint, error_string, " can't find " + octopusOrigami_path + "; check compiling instructions in that directory?"
			for i=0, n_elements(f)-1 do begin
				if ~is_uptodate(f[i] +'.bls',f[i]) then begin

						mprint, doing_string, 'running octopusOrigami with the following command:'
					mprint, tab_string, octopusOrigami_path + ' ' + f[0]
					spawn, octopusOrigami_path + ' ' + f[i]
					mprint, done_string
				endif else begin
					mprint, tab_string + skipping_string + 'not re-phasefolding ' + f[i]
					mprint, tab_string + tab_string +  'because ' + f[i] + '.bls is more recent it'
				endelse
			endfor
		endif else mprint, skipping_string, 'no MarPLES were found for ' + star_dir() + '; skipping origami search'

		;extract_candidates_from_origami

		; clean up inprogress file
		file_delete, star_dir() + 'octopusinprogress.txt', /allow
	endif else begin
		mprint, skipping_string, 'not running call_origami_bot.pro because it may already be running somewhere else'
		mprint, tab_string, 'delete '+ star_dir() + 'octopusinprogress.txt'+ ' or run with /bulldoze to continue'
	endelse
END




