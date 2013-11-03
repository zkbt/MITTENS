PRO ds9_some_hjds, input_hjd, xpa_name=xpa_name,  filenames=filenames, maxn=maxn, pid=pid

	hjd = input_hjd[sort(input_hjd)]
	common this_star
	@filter_parameters
	restore, star_dir + 'raw_target_lc.idl'	
	restore, star_dir + 'raw_ext_var.idl'
	match_tel = file_test(star_dir + 'raw_tel_array.idl')
	if match_tel then restore, star_dir + 'raw_tel_array.idl'

	sorted = sort(target_lc.hjd)
;	i_hjdmatch = sorted[value_locate(target_lc[sorted].hjd - ext_var[sorted].exptime/2.0/24./60./60, hjd)]
	i_hjdmatch = sorted[value_locate(target_lc[sorted].hjd, hjd + 0.5/60.0/60.0/24.0)]
	midexp_mjds = ext_var[i_hjdmatch].mjd_obs
	if match_tel then midexp_tel = raw_tel_array[i_hjdmatch]
	
	restore, star_dir + 'jmi_file_prefix.idl'
	object_name = stregex(jmi_file_prefix, 'lspm[0-9]+', /extra)
	sql_query = "select object, tel, night, mjd, exptime, filename, rcore from frame where object like '%"+object_name+"%';"
	sql = pgsql_query(sql_query, /verb)
	sql = sql[sort(sql.mjd)]
		; sql.mjd seems to be start of exposure
		; ext_var.mjd_obs seems to be mid exposure
	;;;;;	i_match = value_locate(sql.mjd, midexp_mjds);+ sql.exptime
		for i=0, n_elements(midexp_mjds)-1 do begin
			success = 0
			offset = (sql.mjd + 0.5*sql.exptime/24.0d/60.0d/60.0d) - midexp_mjds[i]
			if match_tel then begin
				this_tel = midexp_tel[i]
				i_righttel = where(sql.tel eq this_tel, n_righttel)
				if n_righttel gt 0 then begin
					i_match = i_righttel[where(abs(offset[i_righttel]) eq min(abs(offset[i_righttel])), n_match)]
					if n_match gt 0 then success = 1
				endif
			endif else begin
				i_match = where(abs(offset) eq min(abs(offset)), n_match)
				success = 1
			endelse
			print, 'want  ', string(format='(F12.6)', midexp_mjds[i]), ' on tel', string(sql[i_match].tel, form='(I02)'),';'
			print, 'found ', string(format='(F12.6)', sql[i_match].mjd + 0.5*sql[i_match].exptime/24.0d/60.0d/60.0d), ' on tel', string(form='(I02)', sql[i_match].tel),' in SQL database;'
			print, 'offset by ', 24.*60.*60.*offset[i_match], ' seconds'
			if success eq 1 then begin
				if n_elements(big_i_match) eq 0 then big_i_match = i_match else big_i_match = [big_i_match, i_match]
			endif else begin
				print, 'FAILURE!'
				stop
			endelse
			print
		endfor
		short_filenames = rw(sql[big_i_match].filename)
		apertures = sql[big_i_match].rcore
		tel_dir = 'tel'+stregex(stregex(short_filenames, 't[0-9][0-9]', /ext), '[0-9]+', /ext) +'/'
		date_dir = stregex(stregex(short_filenames, 'obj.[0-9]+', /ext), '[0-9]+', /ext) +'/'
		prefix = '{/data/mearth1/reduced/,/data/mearth2/*/reduced/}' + tel_dir + date_dir
		filenames = file_search(prefix + short_filenames)
		ds9_filenames, filenames, xpa_name=xpa_name, mjd_i_think=midexp_mjds, apertures=apertures, pid=pid



	
END