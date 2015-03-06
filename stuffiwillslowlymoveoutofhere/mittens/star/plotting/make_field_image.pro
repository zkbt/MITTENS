PRO make_field_image, star_dir, jmi_file_prefix, pixels=pixels, remake=remake, old=old

	if not keyword_set(prefix) then prefix = ''
	if not keyword_set(suffix) then suffix = ''
	@mearth_dirs


		if keyword_set(star_dir) then begin
			tel = uint(strmid(stregex(star_dir, 'tel0[1-8]', /extract), 3,2))
			lspm = uint(strmid(stregex(star_dir, 'lspm[0-9]+', /extract), 4,4))
		endif else begin
			lspm_string = 'lspm' + strcompress(/remove_all, lspm)
			tel_string = 'tel0'+strcompress(/remove_all, tel)
			star_dir = 'stars/' + tel_string+lspm_string+suffix+'/'+prefix
		endelse
		tel_dir = 'tel0' + string(format='(I1)', tel)
		lspm_dir = 'lspm' + strcompress(/remove_all, lspm)

		master_link = stregex(/extract, jmi_file_prefix, '[^_]+') + '_master.fit'
		test = file_info(master_link)
		if test.symlink eq 0 and test.dangling_symlink eq 0 then relative_image_path = master_link else begin
			path = strmid(jmi_file_prefix, 0, strpos(jmi_file_prefix, 'lspm'))
			relative_image_path = file_readlink(path + file_readlink(master_link)) 
		endelse
		if strmatch(relative_image_path, reduced_dir+'*') then absolute_image_path = relative_image_path else absolute_image_path = reduced_dir + tel_dir + '/master/' + relative_image_path
		
		template_path = '/home/zberta/mearth/work/panda.tpl'
		image_path =star_dir + 'field.jpg'
					l = get_lspm_info(lspm)
					rah = long(l.ra/15)
					ram = long((l.ra/15 - rah)*60)
					ras = ((l.ra/15 - rah)*60 - ram)*60
	
					decd = long(l.dec)
					decm = long((l.dec - decd)*60)
					decs = ((l.dec - decd)*60-decm)*60
	
					
					pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)');+ "  (J2000)"
		if file_search(image_path) eq '' or keyword_set(remake) then begin
			f = file_search(absolute_image_path)
			if not keyword_set(pixels) then pixels=400 ;(makes 10 arcminute box)
			spawn, 'ds9 ' + f[0] + ' -scale mode zscale -scale squared -cmap invert yes -colorbar no -height '+strcompress(/remove_all, pixels)+' -width '+strcompress(/remove_all, pixels)+' -zoom to 0.5 -pan to '+pos_string+' wcs fk5 -regions template '+template_path + ' at '+ pos_string + ' fk5 -raise -saveimage jpeg ' + image_path + ' -exit'
			print, '        made a new field image!'
		endif else print, '        field image already exists!'


END