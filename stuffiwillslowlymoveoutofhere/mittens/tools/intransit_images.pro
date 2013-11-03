PRO intransit_images, candidate, xpa_name=xpa_name, hjds=hjds, filenames=filenames, buffer=buffer
	common this_star
	restore, star_dir + 'raw_target_lc.idl'
	restore, star_dir + 'raw_ext_var.idl'
	match_tel = file_test(star_dir + 'raw_tel_array.idl')
	if match_tel then restore, star_dir + 'raw_tel_array.idl'
	i_ok = where(target_lc.okay, n_ok)
	i_okandintransit = i_ok[where_intransit(target_lc[i_ok], candidate, n_intransit,buffer=buffer)]

	if n_intransit gt 0 then begin
		hjds = target_lc[i_okandintransit].hjd
		midexp_mjds =ext_var[i_okandintransit].mjd_obs
		if match_tel then midexp_tel = raw_tel_array[i_okandintransit]
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
		load_image, filenames, xpa_name=xpa_name, mjd_i_think=midexp_mjds; /master,

; stop
; ; ================================= PICK UP FROM HERE!
; 		filename = jmi_file_prefix+'_lc.fits'
; 		fits_lc = mrdfits(filename, 1, header_lc, status=status, /silent)
; 		mjds = sxpar(header_lc, 'MJDBASE') + jxpar(header_lc, 'TV*', n_array)
; 
; 		i_targets = where(fits_lc.class eq 9, n_targets)
; 		if n_targets gt 1 then hjds_of_raw_images = total(/double, fits_lc[i_targets].hjd, 2)/n_targets else hjds_of_raw_images = fits_lc[i_targets].hjd
; 
; 		for j=0, n_intransit -1 do begin
; 			this= where(abs(hjds_of_raw_images - hjds[j]) eq min(abs(hjds_of_raw_images - hjds[j])) and abs(hjds_of_raw_images - hjds[j]) lt 5/60./60./24., n_image)
; 			if n_image ne 1 then begin
; 				print, 'COULD NOT MATCH UP IMAGES - YOUR CODE IS PROBABLY BROKEN!'
; 				stop
; 			endif else begin
; 				if n_elements(i_images) eq 0 then i_images = this else i_images = [i_images, this]
; 			endelse
; 		endfor
; 
; 		image_names = strarr(n_elements(target_lc))
; 		openr, lun, /get_lun, jmi_file_prefix + '.list'
; 		readf, lun, image_names
; 		close, lun
; 		free_lun, lun
; 		link_to_images = repstr(jmi_file_prefix + stregex( /ext, image_names[i_images], '/.+'), '_list.fits', '.fit')
; 		for j=0, n_intransit-1 do if j eq 0 then filenames = master_image_path(link_to_images[j]) else filenames = [filenames, master_image_path(link_to_images[j])]
; 		load_image, filenames, /master, xpa_name=xpa_name, mjd_i_think=mjds[i_images]
	endif
END