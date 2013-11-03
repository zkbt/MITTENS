FUNCTION make_weather_night, dusk, dawn, date_string=date_string
	
	hour = 1.0/24.0
	; use awk to read in the night's weather
	awk_command = "awk ' $1 > " + string(dusk, format='(D)')  + " && $1 < " + string(dawn, format='(D)') + " && ! /--- ---/ { if ($14 ~ /---/) print $1, $2, $3, $4, $6, $7, -274, $15; else print $1, $2, $3, $4, $6, $7, $14, $15 }' nights/weather/weather.log"
	spawn,awk_command, weather_strings
;	print, weather_strings
	n_rows = n_elements(weather_strings)
	print, '    | reading weather information for the night'
	print, '         + ', n_rows, ' weather points available'
	; convert awk string output to numbers	
	if n_rows gt 1 then begin
		if weather_strings[0] ne '' then begin
			for i=0, n_elements(weather_strings)-1 do weather_strings[i] =  str_replace(weather_strings[i], '---', '-999', /global) 
			a = dblarr(8, n_rows)	
			reads, weather_strings, a
		endif else begin
			a = [dusk, -1]
		endelse
	
		w = {MJD:a[0,*], winddir:a[1,*], windspd:a[2,*], temp:a[3,*], humidity:a[4,*], pressure:a[5,*], skytemp:a[6,*], alert:a[7,*]}
	
	endif else begin
		w = {MJD:0, winddir:0, windspd:0, temp:0, humidity:0, pressure:0, skytemp:0, alert:0}
	endelse
	save, filename='nights/weather/'+ date_string + '.idl', w
	return, w
;	alert_names = ['cold', 'hot', 'dew', 'humid', 'windy', 'rain', 'sun', 'weatherless', 'cloud']
;	for i=0, n_rows-1 do i_alerts = where(
;use constant ALERT_MIN_TEMP       => 0x0001;
;use constant ALERT_MAX_TEMP       => 0x0002;
;use constant ALERT_DEW            => 0x0004;
;use constant ALERT_MAX_HUMIDITY   => 0x0008;
;use constant ALERT_MAX_WIND_SPEED => 0x0010;
;use constant ALERT_RAIN           => 0x0020;
;use constant ALERT_SUN            => 0x0040;
;use constant ALERT_NOWX           => 0x0080;
;use constant ALERT_CLOUD          => 0x0100;		
END 

;	awk_command = "awk ' $1 > " + string(dusk, format='(D)')  + " && $1 < " + string(dawn, format='(D)') + "{ if ($14 ~ /---/) print $1, $2, $3, $4, $6, $7, -274, $15; else print $1, $2, $3, $4, $6, $7, $14, $15 }' nights/weather/weather.log"
;		w = {MJD:a[0,*], winddir:a[1,*], windspd:a[2,*], temp:a[3,*], humidity:a[4,*], pressure:a[5,*], skytemp:a[6,*], alert:a[7,*]}
;		w = {MJD:0, winddir:0, windspd:0, temp:0, humidity:0, pressure:0, skytemp:0, alert:0}
