PRO get_dark, date, night_MJD, morning_MJD
	date_string = string(date, format='(I8)')
	print, '    | getting dark times from simpleobserve file on mearth'
	simp = file_search('nights/simpleobserves/*'+date_string+'*')
	error = ''
	if simp eq '' then begin
		spawn, 'rsync -vaz mearth@mearth.sao.arizona.edu:mearth/log/'+date_string+'/simpleobserve.pl.tel01.'+date_string+ '.log nights/simpleobserves/.', result, error
		if error[0] ne '' then spawn, 'rsync -vaz mearth@mearth.sao.arizona.edu:mearth/log/simpleobserve.pl.tel01.'+date_string+ '.log nights/simpleobserves/.', result, error
	endif
	if (error[0] eq '') then begin
		spawn, "awk ' /Evening Observations/ { print $6}' nights/simpleobserves/simpleobserve.pl.tel01."+date_string+".log", night_string
		spawn, "awk ' /Morning Observations/ { print $6}' nights/simpleobserves/simpleobserve.pl.tel01."+date_string+".log", morning_string
		night_MJD = float(night_string[0])
		morning_MJD = float(morning_string[0])
		print, '        + simpleobserve found, dark time taken from that to be'
		print, '           dusk: ', night_MJD, ', dawn: ', morning_MJD
	endif else begin
		night_MJD = -1
		morning_MJD = -1
	endelse
END
