FUNCTION make_weather_night, dusk, dawn, date_string=date_string
	
	; use awk to read in the night's weather
	spawn, "awk ' $1 > " + string(dusk) + " && $1 < " + string(dawn) + "{ print $0}' weather.log", weather_strings
	n_rows = n_elements(weather_strings)

	; rows are different length if they were made before or after the cloud sensor was added
	if dusk le 54637.75 then n_cols = 14 else n_cols = 15
	
	; convert awk string output to numbers
	a = fltarr(n_cols, n_rows)
	reads, weather_strings, a
	
	if n_cols eq 14 then sky_temp=fltarr(n_rows)-999 else sky_temp=a[13,*]
	
	save, filename='nights/weather/'+ date_string + '.idl'
	w = {MJD:a[0,*],$
		wind_dir:a[1,*],$
		wind_speed:a[2,*],$
		temp:a[3,*],$
		dewpoint:a[4,*],$
		humidity:a[5,*],$
		pressure:a[6,*],$
		rain_accum:a[7,*],$
		rain_dur:a[8,*],$
		rain_inten:a[9,*],$
		hail_accum:a[10,*],$
		hail_dur:a[11,*],$
		hail_inten:a[12,*],$
		sky_temp:sky_temp,$
		alert:a[n_cols-1,*]}
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

