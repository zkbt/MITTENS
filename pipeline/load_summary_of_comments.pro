PRO load_summary_of_comments, summary_of_comments

	common mearth_tools
	common this_star

	; keep track of the original star dir, so we can come back to it
	original_mo = name2mo(currentname())

	; find all comments
	f = file_search('mo*/combined/comments.log')

	; convert these to mo's
	mo = name2mo(f)
	n = n_elements(f)

	; create a template for the flags we want to keep track of
	template = create_struct('MO', '', {ignore:0B, known:0B, variability:0B} )
	summary_of_comments = replicate(template, n)

	; loop over the comment files
	mprint, doing_string, 'making a summary of the comments; saving to population/summary_of_comments.idl'
	for i=0, n-1 do begin
		set_star, mo[i]
		s = template
		if file_test(f[i]) then begin
			comments = ''
			openr, lun, /get_lun, f[i]
			while eof(lun) eq 0 do begin
				readf, lun, comments
				if strmatch(comments, '*IGNORE*', /fold_case) then s.ignore = 1
				if strmatch(comments, '*VARIAB*', /fold_case) then s.variability = 1
				if strmatch(comments, '*KNOWN*', /fold_case) then s.known = 1
			endwhile
			close, lun
			free_lun, lun
		endif
		summary_of_comments[i] = s
		summary_of_comments[i].mo = mo[i]
		mprint, tab_string, mo[i]
	endfor
	save, summary_of_comments, filename='population/summary_of_comments.idl'
	set_star, original_mo

END
