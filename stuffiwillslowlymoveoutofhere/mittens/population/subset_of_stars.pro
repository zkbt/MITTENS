FUNCTION subset_of_stars, year=year, tel=tel, lspm=lspm, radius_range=radius_range, suffix, n=n, combined=combined
	if keyword_set(lspm) then ls_string= 'ls'+string(format='(I04)', lspm) + '/' else ls_string = 'ls*/'
	if keyword_set(year) then ye_string= 'ye'+string(format='(I02)', year mod 100) + '/' else ye_string = 'ye*/'
	if keyword_set(tel) then te_string= 'te'+string(format='(I02)', tel) + '/' else te_string = 'te*/'
	if not keyword_set(suffix) then suffix=''
	if n_elements(n) eq 0 then n = 0

	if keyword_set(combined) then begin
		if keyword_set(year) then begin
			search_string = ls_string + '/'+ye_string + '/combined/' 
		endif else search_string = ls_string + '/combined/'
	endif else search_string = ls_string + ye_string + te_string
	f = file_search(search_string + suffix, /mark_dir)

	if keyword_set(radius_range) then begin
		ls = stregex(stregex(f, /ext, 'ls[0-9]+'), /ext, '[0-9]+')
		restore, 'lspm_properties.idl'
		radii = radius[ls]
		i = where(radii ge min(radius_range) and radii lt max(radius_range), n_radii)
		if n_radii gt 0 then begin
			i = i[sort(radii[i])]
			f = f[i] 
		endif else print, 'NOT ENOUGH STARS IN YOUR RADIUS RANGE!'
	endif

	dirs = stregex(f, /ext, 'ls[0-9]+/(ye[0-9]+|combined)/((te[0-9]+|combined)/)?') ; stregex(/ext, f, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
	if keyword_set(n) then begin
		enough = bytarr(n_elements(dirs))
		for i=0, n_elements(f)-1 do begin
			if file_test(dirs[i] + 'target_lc.idl') then begin
				restore, dirs[i]+ 'target_lc.idl'
				if n_elements(target_lc) gt n then enough[i] = 1
			endif else begin
				if file_test(dirs[i] + 'inflated_lc.idl') then begin
					restore, dirs[i]+ 'inflated_lc.idl'
					if n_elements(inflated_lc) gt n then enough[i] = 1
				endif
			endelse
		endfor
		i_enough = where(enough, n_enough)
		if n_enough gt 0 then dirs = dirs[where(enough)] else print, 'NOT ENOUGH STARS WITH N DATA POINTS!'
	endif
	return, dirs
END