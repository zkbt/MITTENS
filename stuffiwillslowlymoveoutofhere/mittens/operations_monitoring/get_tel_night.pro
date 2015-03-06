FUNCTION make_tel_night, date, tel, silent=silent, observed=observed
	
	if NOT keyword_set(silent) then	t_elapsed = - systime(/seconds)
	
	dir = '/pool/barney0/mearth/lightcurves/'
	date_string = string(date, format='(I8)')
	tel_string = 't0' + string(tel, format='(I1)')
	command = 'ls -R ' + dir + '*/*/' + tel_string + '.obj.' + date_string + '*_list.fits'
	spawn, command, list_files
	n_obs = n_elements(list_files)
	
	tel_obs = {seeing:0.0, magzpt:0.0, airmass:0.0, mjdobs:0.d, tamb:0.0, winddir:0.0, windspd:0.0, dewpoint:0.0, humidity:0.0, pressure:0.0, skytemp:0.0} 			; weather
	tags = tag_names(tel_obs)
	tags[where(tags eq 'MJDOBS')] = 'MJD-OBS'
	obs = replicate(tel_obs, n_obs)

	; read in the observation logs from the night
	if (n_obs gt 1) then begin
		for i=0, n_elements(list_files)-1 do begin
			header = headfits(list_files[i], exten=1)
			for j=0, n_elements(tags)-1 do obs[i].(j) = sxpar(header,tags[j])
		endfor
		if NOT keyword_set(silent) then begin
			t_elapsed += systime(/seconds)
			print, n_obs, ' science headers from the night of ', date_string, ' on telescope ', tel_string, ' read in ', string(t_elapsed, format='(F3.1)'), ' seconds' 
		endif
		observed = 1
	endif else begin
			print, 'not enough observations found on the night of ', date_string, ' on telescope ', tel_string
			observed = 0
	endelse
	
	; get the start and end times for the night from the simpleobserve logs
	get_dark, date, night_MJD, morning_MJD
	
	if (night_MJD eq -1) or (morning_MJD eq -1) then begin
			print, "couldn't read the times from simpleobserve for ", date
			y = date/10000
			m = (date/100) mod 100
			d = date mod 100
	
			jd_night = julday(m, d, y)
			n_days = 14
			jd_nights_to_check = jd_night - findgen(14)			
			spawn, 'ls nights/'+tel_string+'/*', previously_done	
			caldat, jd_nights_to_check, m, d, y
			dates = string(y, format='(I04)') + string(m, format='(I02)') + string(d, format='(I02)')
	
			for i=0, n_days-1 do begin
				i_match = where('nights/'+ tel_string + '/' +dates[i]+'.idl' eq previously_done, n_match)
				if (n_match gt 0) then begin
					restore, 'nights/' + tel_string + '/' +dates[i]+'.idl'
					night_MJD = tel_night.night
					morning_MJD = tel_night.morning
					print, '   read them from ', dates[i], ' instead'
					break
					
				endif
			endfor	
	endif
	
	
	tel_night = {obs:obs, night:night_MJD,  morning:morning_MJD, observed:observed}
	save, tel_night, filename='nights/' + tel_string + '/' + date_string+'.idl'	
	
	if tel eq 1 then w = make_weather_night(night_MJD, morning_MJD, date_string=date_string)
	return, tel_night
END 