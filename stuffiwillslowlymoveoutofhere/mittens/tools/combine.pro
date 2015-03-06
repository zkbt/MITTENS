PRO combine_lightcurves, lspm
	lspm_dir = 'ls'+string(format='(I04)', lspm)+'/'
	f = file_search(lspm_dir + '*/*/', /mark_dir)
help
	for i=0, n_elements(f)-1 do begin
		star_dir = f[i]
		if file_test(star_dir+ 'medianed_lc.idl') then begin
			restore, star_dir + 'medianed_lc.idl'
			restore, star_dir + 'target_lc.idl'
			restore, star_dir + 'decorrelated_lc.idl'
			restore, star_dir + 'ext_var.idl'
			if n_elements(big_medianed_lc) eq 0 then big_medianed_lc = medianed_lc else big_medianed_lc = [big_medianed_lc, medianed_lc]
			if n_elements(big_decorrelated_lc) eq 0 then big_decorrelated_lc = decorrelated_lc else big_decorrelated_lc = [big_decorrelated_lc, decorrelated_lc]
			if n_elements(big_target_lc) eq 0 then big_target_lc = target_lc else big_target_lc = [big_target_lc, target_lc]
			if n_elements(big_ext_var) eq 0 then big_ext_var = ext_var else big_ext_var = [big_ext_var, ext_var]
help
		endif
	endfor
	i = sort(big_medianed_lc.hjd)
	medianed_lc = big_medianed_lc[i]
	target_lc = big_target_lc[i]
	decorrelated_lc = big_decorrelated_lc[i]
	ext_var = big_ext_var[i]
	star_dir = lspm_dir + 'combined/'
	file_mkdir, star_dir
	save, filename=star_dir + 'medianed_lc.idl', medianed_lc
	save, filename=star_dir + 'target_lc.idl', target_lc
	save, filename=star_dir + 'decorrelated_lc.idl', decorrelated_lc
	save, filename=star_dir + 'ext_var.idl', ext_var

END