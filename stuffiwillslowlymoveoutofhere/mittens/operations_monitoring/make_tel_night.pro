PRO make_tel_night, date, tel, silent=silent, observed=observed
	
	if NOT keyword_set(silent) then	t_elapsed = - systime(/seconds)
		date = long(date)
			y = date/10000
			m = (date/100) mod 100
			d = date mod 100
			jd_night = julday(m, d, y)

	date_string = string(date, format='(I8)')
	tel_string = 't0' + string(tel, format='(I1)')	
	print, '% getting the information for ', date_string, ' = ', jd_night, ' on ', tel_string
	dir = '/data/mearth1/reduced/tel0'+string(tel, format='(I1)')+'/' + date_string+'/'

	list_files = file_search(dir + tel_string + '.obj.*_cat.fits')
	n_obs = n_elements(list_files)
	tel_obs = {exptime:0.0, seeing:0.0, magzpt:0.0, magzrr:0.0, airmass:0.0, mjdobs:0.d, stdcrms:0.0, $		; the first 13 are read from headers
				windspd:0.0, humidity:0.0, skytemp:0.0, $
				imgzpt:0.0, imgzrr:0.0, imnzpt:0.0, object:'', $
				ellipticity:0.0, skylev:0.0, skyrms:0.0, peak_height:0.0, $						; the others from the table
				i_obs:-1}					; except for one which is calculated
	n_header_tags = 14	
	tags = tag_names(tel_obs)
	h_tags = tags[0:n_header_tags-1]
	h_tags[where(h_tags eq 'MJDOBS')] = 'MJD-OBS'
	;t_tags = tags[n_header_tags:*]

	obs = replicate(tel_obs, n_obs)
	counter = 0
	object = ''
	
	; read in the observation logs from the night
	if (n_obs gt 1) then begin
		for i=0, n_elements(list_files)-1 do begin
			m = mrdfits(list_files[i], 1, header, /silent)
			if (n_tags(m) gt 0) then begin
				m_tags = tag_names(m)
				for j=0, n_header_tags-1 do obs[i].(j) = sxpar(header,h_tags[j])
				if (where(m_tags eq 'CLASSIFICATION') NE -1) then begin
					i_target = where(m.classification eq 9, n_targets)
					i_star = where(m.classification eq -1 or m.classification eq 9, n_stars)
					for j=n_header_tags, n_elements(tags)-2 do if n_stars gt 0 then obs[i].(j) = mean(m[i_star].(where(m_tags eq tags[j]))) else obs[i].(j) = 999
					previous_obs_of_this_object = where(obs.object eq sxpar(header,'OBJECT'), n_previously_observed)
					obs[i].i_obs = n_previously_observed
				endif
			endif
	

		endfor
		if NOT keyword_set(silent) then begin
			t_elapsed += systime(/seconds)
			print, '        + read ', n_obs, ' science headers in ', string(t_elapsed, format='(F4.1)'), ' seconds' 
		endif
		observed = 1
	endif else begin
			print, '        + not enough observations found'
			observed = 0
	endelse


; get the start and end times for the night from the simpleobserve logs

	if tel eq 1 then get_dark, date, night_MJD, morning_MJD else begin
	;	temp hack to make it run with fewer errors!
		if file_test( 'nights/t01/' +date_string+'.idl') then begin
			restore, 'nights/t01/' +date_string+'.idl'
			night_MJD = tel_night.dusk
			morning_MJD = tel_night.dawn
		endif
	endelse
	
	if (night_MJD eq -1) or (morning_MJD eq -1) then begin
		print, '        + no simpleobserve found, taking dark times from previous night'
		jd_night_to_check = jd_night - 1	
			caldat, jd_night_to_check, test_m, test_d, test_y
			spawn, 'ls nights/'+tel_string+'/*', previously_done	
			test_date = string(test_y, format='(I04)') + string(test_m, format='(I02)') + string(test_d, format='(I02)')
				i_match = where('nights/'+ tel_string + '/' +test_date+'.idl' eq previously_done, n_match)
				if (n_match gt 0) then begin
					restore, 'nights/' + tel_string + '/' +test_date+'.idl'
					night_MJD = tel_night.dusk + 1.0
					morning_MJD = tel_night.dawn + 1.0
					print, '           dusk: ', night_MJD, ', dawn: ', morning_MJD
				endif else print, "           couldn't find previous night's times!"
		tel_night = {obs:obs, dusk:night_MJD, dawn:morning_MJD, observed:observed}

	endif else begin
		tel_night = {obs:obs, dusk:night_MJD, dawn:morning_MJD, observed:observed}
	endelse
	
	
	save, tel_night, filename='nights/' + tel_string + '/' + date_string+'.idl'	
	
	;if tel eq 1 then
	w = make_weather_night(night_MJD, morning_MJD, date_string=date_string)
;	return, tel_night
END 