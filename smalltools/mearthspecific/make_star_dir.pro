FUNCTION make_star_dir, input_mo, year, tel, combined=combined
	
	common mearth_tools
	mo = name2mo(input_mo)
  	mo_string = mo_prefix + mo
  
	; use available years, if not specified
	if n_elements(year) eq 0 then begin
		ye_string = stregex(file_search(mo_string + '/ye*/*'), 'ye[0-9]+',/extract)
	endif else begin
		ye_string = 'ye' + string(format='(I02)', year mod 2000)
	endelse

	; if no telescope is specified, include
	if n_elements(tel) eq 0 then begin
		for j=0, n_elements(ye_string) -1 do begin
			te_string = stregex(file_search(mo_string + '/' + ye_string[j] + '/*/'), 'te[0-9]+',/extract)
			for i=0, n_elements(te_string)-1 do begin
				if i eq 0 and j eq 0 then begin
					star_dir = mo_string + '/' + ye_string[j] + '/' + te_string[i] + '/' 
				endif else begin 
					star_dir = [star_dir, mo_string + '/' + ye_string[j] + '/' + te_string[i] + '/']
				endelse
			endfor
		endfor
	endif else begin
		te_string = 'te' + string(format='(I02)', tel)
		star_dir = mo_string + '/' + ye_string + '/' + te_string + '/'
	endelse
	if keyword_set(combined) then begin
		if keyword_set(year) then begin
			star_dir = mo_string + '/' + ye_string + '/combined/' 
		endif else star_dir = mo_string + '/combined/'
	endif

	unique = uniq(star_dir, sort(star_dir))
	star_dir = star_dir[unique[sort(long(stregex(/ex, stregex(/ex, star_dir[unique], 'ye[0-9]+'), '[0-9]+')))]]
	if n_elements(star_dir) gt 1 then begin
		for i=0, n_elements(star_dir)-1 do begin
			print, i, '   ', star_dir[i]
			str = '           '
			if file_test(star_dir[i] + 'target_lc.idl') then begin
				restore, star_dir[i] + 'target_lc.idl'
				str += rw(n_elements(target_lc))+ ' squashed light curve points'
			endif
			if file_test(star_dir[i] + 'box_pdf.idl') then begin
				restore, star_dir[i] + 'box_pdf.idl'
				str += ', '+rw(n_elements(boxes))+ ' boxes'
			endif
			print, str
		endfor
		print
		return, star_dir[question('which star_dir would you like?', /int, /num)]
	endif
 return, star_dir
END