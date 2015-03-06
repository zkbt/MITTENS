PRO plot_days, range, tel, filename=filename,  dt_max, max_wind, zero_point, zero_error, hours=hours, seeing=seeing, ellipticity=ellipticity, stdcrms=stdcrms

	@define_colors.pro
	
	;dt_max = 5./60./24.
	!p.charsize=1
	tel_string = 't0' + string(tel, format='(I1)')
	bigger_tel_string = 'tel0' + string(tel, format='(I1)')
	y = range/10000
	m = (range/100) mod 100
	d = range mod 100
	
	jd_range = julday(m, d, y)
	n_days = jd_range[1] - jd_range[0] +1
	jd = indgen(n_days) + jd_range[0]
	
	caldat, jd, m, d, y
	dates = string(y, format='(I04)') + string(m, format='(I02)') + string(d, format='(I02)')
	
	if keyword_set(filename) then begin
		set_plot, 'ps'
		device, filename=filename, /encapsulated, /color
	endif
	
	spawn, 'ls nights/'+tel_string+'/*', previously_done
	
	dusk = fltarr(n_days)
	dawn = dusk
	
	zero_point = 0.0
	zero_error = 0.0
	
	hour = {good:0.0, bad:0.0, photometric:0.0, bad_weather:0.0, total:0.0, exposing:0.0, jd:0.0d, n_obs:0, n_good_image:0, n_good_photometry:0}
	hours = replicate(hour, n_days)
	hours.jd = jd
	
	for i=0, n_days-1 do begin
		i_match = where('nights/'+ tel_string + '/' +dates[i]+'.idl' eq previously_done, n_match)
		if (n_match gt 0) then begin
			restore, 'nights/' + tel_string + '/' +dates[i]+'.idl' 
			dusk[i] = tel_night.dusk
			dawn[i] = tel_night.dawn
			zero_point = [zero_point, tel_night.obs.imgzpt]
			zero_error = [zero_error, tel_night.obs.imgzrr]
		endif else	print, 'you still need to make', dates[i], '!'
	endfor
	
;	zero_point = zero_point[1:*]
;	zero_error = zero_error[1:*]

;	i_goodzp = where(zero_error gt 0 and zero_point gt 0)

;	zero_point = zero_point(i_goodzp)
;	zero_error = zero_error(i_goodzp)	
;	median_zero = median(zero_point)
;	print, 'median zero point for tel', tel, ':', median_zero
;	zero_width = robust_sigma(zero_point)
;	print, 'the robust error on this is:', zero_width
	!p.thick=1
	!p.charthick=2
	wx_alerts = [256, 128, 64, 32, 16, 8, 4, 2, 1]
	wx_names = ['cloud', 'no weather', 'sun', 'rain', 'windy', 'humid', 'dew', 'hot', 'cold']
;	wx_colors = [	 0, 		25,		215,	100,	     125, 	 150, 	75,	  250,  75]
	wx_colors = fltarr(9)
	n_alerts = n_elements(wx_alerts)
	wx_orient = indgen(n_alerts)*180/n_alerts
	loadct, 39
	plot, [jd-1,jd+1], [dusk,dawn] mod 1.0, xstyle=1, psym=1, xtickunits=['Time'], title='tel'+string(tel, format='(I02)') + ' (' + string(range[0], format='(I8)') + '-' + string(range[1], format='(I8)') + ')', /nodata, ytickname=['Dusk', 'Midnight', 'Dawn'], yticks=2, xticklayout=1, yticklayout=1, ystyle=1

	spawn, 'ls ~/mearth/work/stars/'+bigger_tel_string+'lspm*/bad_mjd.idl', bad_mjd_files
	for j=0, n_elements(bad_mjd_files)-1 do begin
				restore, bad_mjd_files[j]
				object_array = strarr(n_elements(bad_mjd))
				object_array[*] = strmid(bad_mjd_files[j], strpos(bad_mjd_files[j], 'lspm'), strpos(bad_mjd_files[j], '/bad') - strpos(bad_mjd_files[j], 'lspm'))

				if n_elements(big_bad_mjd) eq 0 then big_bad_mjd =bad_mjd else big_bad_mjd= [big_bad_mjd, bad_mjd]
				if n_elements(big_object) eq 0 then big_object = object_array else big_object = [big_object, object_array]
				

			endfor



	for i=0, n_days-1 do begin
		circuit =  [jd[i]-.5, jd[i]-.5, jd[i]+.5, jd[i]+.5] 
		i_match = where('nights/'+ tel_string + '/' +dates[i]+'.idl' eq previously_done, n_match)
		if (n_match gt 0) then begin
			restore, 'nights/' + tel_string + '/' +dates[i]+'.idl' 
			restore, 'nights/weather/' +dates[i]+'.idl' 
			hours[i].total = (tel_night.dawn - tel_night.dusk)*24
			
			tel_night.obs = tel_night.obs[sort(tel_night.obs.mjdobs)]
			obs_is_bad = bytarr(n_elements(tel_night.obs))

			; plot the telescope time
			n_obs = n_elements(tel_night.obs)
			hours[i].n_obs = n_obs
			hours[i].n_good_photometry = n_obs
			hours[i].n_good_image = n_obs
			
				for k=0, n_elements(big_bad_mjd)-1 do begin
					i_obs_is_bad = where(abs(tel_night.obs.mjdobs - big_bad_mjd[k]) le 0.00694 and tel_night.obs.object eq big_object[k], n_badobs_match)
					if n_badobs_match then begin
						;	print, ' IMAGE OBS', string(tel_night.obs[i_obs_is_bad].mjdobs, format='(D)')
						;	print, ' BAD OBS  ', string(mjd_bad_obs[k], format='(D)')
							obs_is_bad[i_obs_is_bad] += 1
							hours[i].n_good_photometry -= 1
					endif
				endfor

			
			for j=0, n_obs-2 do begin
				dt = min([dt_max, tel_night.obs[j+1].mjdobs - tel_night.obs[j].mjdobs])				

				if (tel_night.obs[j].seeing lt seeing and tel_night.obs[j].ellipticity lt ellipticity and tel_night.obs[j].stdcrms lt stdcrms) then begin
					if (obs_is_bad[j] gt 0) then begin
						color =	unphotometric_image_color
					endif else begin
						hours[i].photometric += dt*24.
						color = photometric_image_color
					endelse
					;if (tel_night.obs[j].windspd gt max_wind) then color = 215
					hours[i].good += dt*24.
				endif else begin
					hours[i].n_good_image -= 1
					;if (tel_night.obs[j].windspd gt max_wind) then color = 30 else 
					if (obs_is_bad[j] gt 0) then begin
						color = unphotometric_unimage_color
					endif else begin
						hours[i].photometric += dt*24.
						color= photometric_unimage_color
					endelse
					hours[i].bad += dt*24.
				endelse
				hours[i].exposing += tel_night.obs[j].exptime/3600.0
				polyfill, circuit, [tel_night.obs[j].mjdobs, tel_night.obs[j].mjdobs+dt, tel_night.obs[j].mjdobs+dt, tel_night.obs[j].mjdobs] - (jd[i]-2400000), color=color
			endfor
			hours[i].exposing += tel_night.obs[n_obs-1].exptime/3600.0
			; plot the weather alerts
			n_w = n_elements(w.alert)
			;print, dates[i], n_w, w.mjd[0]
			
			for j=0l, n_w - 2 do begin
					
					for k=0, n_alerts-1 do begin
						if (w.alert[j]/wx_alerts[k] mod 2 gt 0.0) then begin
							box = [w.mjd[j], w.mjd[j+1], w.mjd[j+1], w.mjd[j]] - (jd[i]-2400000)
							polyfill, circuit, box, color=wx_colors[k], /line_fill, orientation=wx_orient[k], spacing=.3
						endif
					endfor
				if (w.alert[j] gt 0.0) then begin
					if((w.mjd[0,j+1] - w.mjd[0,j])*24 lt 1.0) then hours[i].bad_weather += (w.mjd[0,j+1] - w.mjd[0,j])*24.
					;print, hours[i].bad_weather
				endif
			endfor
			


			
		endif else	print, 'you still need to make', dates[i], '!'
	endfor

	
;	for i=0, n_elements(bad_hjd[*,0])-1 do begin
;		night = long(bad_hjd[i])
;		circuit =  [night-.5, night-.5,night+.5, night+.5] 
;		dt = min([dt_max,bad_hjd[i,1]-bad_hjd[i,0]])
;		box = [bad_hjd[i,0], bad_hjd[i,0]+dt, bad_hjd[i,0]+dt,bad_hjd[i,0]] - night
;		polyfill, circuit+2400000, box, color=75
;	endfor
	
	
	if keyword_set(filename) then begin
		device, /close
		set_plot, 'x'
	endif
END