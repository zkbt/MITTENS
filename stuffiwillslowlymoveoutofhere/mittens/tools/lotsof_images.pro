PRO lotsof_images, xpa_name=xpa_name, hjds=hjds, filenames=filenames, maxn=maxn
	common this_star
	@filter_parameters
	restore, star_dir + 'raw_target_lc.idl'	
	restore, star_dir + 'raw_ext_var.idl'
	match_tel = file_test(star_dir + 'raw_tel_array.idl')
	if match_tel then restore, star_dir + 'raw_tel_array.idl'

	i_ok = where(target_lc.okay and target_lc.hjd gt 55100, n_tonight)
	if keyword_set(maxn) then begin
; 		nights = round(target_lc.hjd - mearth_timezone())
; 		uniq_nights = nights[uniq(nights, sort(nights))]
; 		for i=0, n_elements(uniq_nights)-1 do begin
; 			i_close = where(abs(target_lc[i_ok].hjd - night) lt 1.0, n_close)
; 			if n_close gt 0 then begin
; 				i_this = i_ok[i_close[randomu(seed)*n_close]]
; 				if n_elements(i_touse) eq 0 then i_touse = i_this else i_touse = [i_touse, i_this]
; 			endif	
; 		endfor
; 		i_ok = i_touse[randomu(seed, maxn)*n
	endif
	i_okandtonight = i_ok;[where(abs(target_lc[i_ok].hjd - hjd) lt 0.3, n_tonight)]
;i = where_intransit(target_lc, candidate, n_tonight)

	if n_tonight gt 0 then begin
		hjds = target_lc[i_okandtonight].hjd
		midexp_mjds =ext_var[i_okandtonight].mjd_obs
		if match_tel then midexp_tel = raw_tel_array[i_okandtonight]
		restore, star_dir + 'jmi_file_prefix.idl'
		object_name = stregex(jmi_file_prefix, 'lspm[0-9]+', /extra)
		sql_query = "select object, tel, night, mjd, exptime, filename from frame where object like '%"+object_name+"%';"
; 		sql_query = "select object, tel, night, mjd, exptime, filename from frame where object like '"+object_name+"';"
		command = 'psql -tc "' + sql_query + '"'
		command += " > " +star_dir() + "sql_output.txt"
		spawn, command
		readcol, star_dir() + "sql_output.txt", sql_object, sql_tel, sql_night, sql_mjd, sql_exptime, sql_filename, delim='|', format='A,L,L,D,L,A'
		sql = struct_conv({object:sql_object, tel:sql_tel, night:sql_night, mjd:sql_mjd, exptime:sql_exptime, filename:sql_filename})
		sql = sql[sort(sql.mjd)]
		
		; sql.mjd seems to be start of exposure
		; ext_var.mjd_obs seems to be mid exposure
		i_match = value_locate(sql.mjd, midexp_mjds);+ sql.exptime
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
		tel_dir = 'tel'+stregex(stregex(short_filenames, 't[0-9][0-9]', /ext), '[0-9]+', /ext) +'/'
		date_dir = stregex(stregex(short_filenames, 'obj.[0-9]+', /ext), '[0-9]+', /ext) +'/'
		prefix = '{/data/mearth1/reduced/,/data/mearth2/*/reduced/}' + tel_dir + date_dir
		filenames = file_search(prefix + short_filenames)
		load_image, filenames, xpa_name=xpa_name, mjd_i_think=midexp_mjds, /blank


; 		restore, star_dir + 'jmi_file_prefix.idl'
; 		image_names = strarr(n_elements(target_lc))
; 		openr, lun, /get_lun, jmi_file_prefix + '.list'
; 		readf, lun, image_names
; 		close, lun
; 		free_lun, lun
; 		link_to_images = repstr(jmi_file_prefix + stregex( /ext, image_names[i_okandtonight], '/.+'), '_list.fits', '.fit')
; 		for j=0, n_tonight-1 do if j eq 0 then filenames = master_image_path(link_to_images[j]) else filenames = [filenames, master_image_path(link_to_images[j])]
; 		load_image, filenames, /master, xpa_name=xpa_name
	endif
END