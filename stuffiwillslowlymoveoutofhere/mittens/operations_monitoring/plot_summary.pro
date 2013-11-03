PRO plot_summary, filename=filename, max_tel=max_tel

	@define_colors.pro
	if keyword_set(filename) then begin
		set_plot, 'ps'
		device, filename='plots/summary_'+filename, /encapsulated, /color, xsize=7.5, ysize=10, /inches
	endif
	!p.thick=2
	!p.multi=[0,1,8]
	loadct, 39

	for tel=1,max_tel do begin	
	
		restore, string(tel, format='(I1)')+'.idl'
		if max(hours.jd) - min(hours.jd) gt 35 then scale = 7 else scale = 2;uint(max(hours.jd) - min(hours.jd))/10
		i = indgen(n_elements(hours.jd)/scale)*scale
		avgd = hours[i]
		for j=0, n_elements(i)-1 do for m=0,9 do if (m ne 6) then avgd[j].(m) = total(hours[j*scale:(j+1)*scale -1].(m))
			total_hours = total(hours.total)
		photometric_hours = total(hours.photometric)
		unphotometric_hours = total(hours.good+hours.bad-hours.photometric)
		weather_hours = total(hours.bad_weather)
		mystery_hours = total(hours.total - hours.good - hours.bad - hours.bad_weather)
		exposure_hours = total(hours.exposing)

		percent_photo = string(100.0*photometric_hours/total_hours, format='(I2)') +'%'
		percent_unphoto = string(100.0*unphotometric_hours/total_hours, format='(I2)') +'%'
		percent_weather = string(100.0*weather_hours/total_hours, format='(I2)') +'%'
		percent_mystery = string(100.0*mystery_hours/total_hours, format='(I2)') +'%'
		percent_exposing = string(100.0*exposure_hours/total_hours, format='(I2)') + '%'
		percent_string = ' (good photometry: '+percent_photo+', bad photometry: '+percent_unphoto+', weather: '+percent_weather+', other: '+percent_mystery+', open shutter: ' + percent_exposing +')'
		if n_elements(avgd.jd) gt 1 then begin
			plot, avgd.jd, avgd.total,yrange=[0,max(avgd.total)], xrange=[min(avgd.jd), max(avgd.jd)+scale], ystyle=1, xstyle=1, xtickunits='Time', title='tel'+string(tel, format='(I02)') + percent_string, /nodata, xticklayout=1, yticklayout=1, ytitle='hours/('+string(scale, format='(I1)')+' days)'
			unphotometric = avgd.good + avgd.bad - avgd.photometric
			mystery = avgd.total - avgd.bad - avgd.good - avgd.bad_weather
			for k=0, n_elements(avgd)-1 do begin
				circuit =  [avgd[k].jd, avgd[k].jd, avgd[k].jd+scale, avgd[k].jd+scale] 
				base = 0.0
				polyfill, circuit, [0,avgd[k].photometric, avgd[k].photometric, 0]+base, color=photometric_color
				base += avgd[k].photometric
				polyfill, circuit, [0,unphotometric[k], unphotometric[k], 0]+base, color=unphotometric_color
				base += unphotometric[k]
				polyfill, circuit, [0,mystery[k], mystery[k], 0]+base, color=255
				base += mystery[k]
				for o=0,180,30 do polyfill, circuit, [0,avgd[k].bad_weather, avgd[k].bad_weather, 0]+base, color=0, /line_fill, orientation=o, spacing=.3
				base += avgd[k].bad_weather
			endfor
			oplot, avgd.jd + scale/2, avgd.exposing, color=0, psym=10
		endif			
	endfor

		if keyword_set(filename) then begin
		device, /close
		set_plot, 'x'
	endif
END
