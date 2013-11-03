PRO redo_saturated
  f = file_search('ls*/ye*/te*/target_lc.idl')
  n = n_elements(f)
  for i=0, n-1 do begin
 	star_dir = strmid(f[i], 0, strpos(f[i], 'target'))
	restore, star_dir + 'ext_var.idl'
	print, star_dir, '   ',  total(ext_var.flags AND 4) 
	; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

	if total(ext_var.flags AND 4) gt 0 then begin
		file_delete, star_dir + 'target_lc.idl', /quiet, /allow
		file_delete, star_dir + 'ext_var.idl', /quiet, /allow
	endif
endfor
END