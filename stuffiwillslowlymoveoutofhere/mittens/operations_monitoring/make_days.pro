PRO make_days, range, tel, weather_only=weather_only
	
	print, '==========================='
	print, 'compiling information on nights', range[0], ' though ', range[1], ' on tel ', tel
	print, '==========================='
	
	if tel eq 1 then begin
		print, '    | syncing the weather log'
		spawn, 'rsync mearth@mearth.sao.arizona.edu:mearth/log/weather.log -vaz nights/weather/weather.log'
	endif else print, '    | assuming the weather log has been synced recently! (redo tel01 if not)'
	tel_string = 't0' + string(tel, format='(I1)')
	
	y = range/10000
	m = (range/100) mod 100
	d = range mod 100
	
	jd_range = julday(m, d, y)
	n_days = jd_range[1] - jd_range[0] +1
	jd = indgen(n_days) + jd_range[0]
	
	caldat, jd, m, d, y
	dates = string(y, format='(I04)') + string(m, format='(I02)') + string(d, format='(I02)')
	
	if not keyword_set(weather_only) then begin
		for i=0, n_days-1 do begin
			make_tel_night, dates[i], tel
		endfor
	endif

END