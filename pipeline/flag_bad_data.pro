PRO flag_bad_data, lenient=lenient, clean=clean, baddatesokay=baddatesokay,trimtransits=trimtransits
;+
; NAME:
;	FLAG_BAD_DATA
; PURPOSE:
;	identify which data points to ignore in unbinned, raw, MEarth light curves (serves as an input for weed_lightcurve)
; CALLING SEQUENCE:
;	flag_bad_data
; INPUTS:
; 	restore, star_dir + 'raw_target_lc.idl'
; 	restore, star_dir + 'raw_comparisons_lc.idl'
; 	restore, star_dir + 'raw_ext_var.idl'
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
; OUTPUTS:
;	save, filename=star_dir + 'raw_target_lc.idl', target_lc
;	save, filename=star_dir + 'bad_mjd.idl', bad_mjd
;	save, filename=star_dir + 'good_mjd.idl', good_mjd
; RESTRICTIONS:
; EXAMPLE:
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-
	common this_star
	common mearth_tools

	restore, star_dir + 'raw_target_lc.idl'
;COMP;
	restore, star_dir + 'raw_comparisons_lc.idl'
	restore, star_dir + 'raw_ext_var.idl'
	file_delete, /allow, /quiet, star_dir + 'target_lc.idl'
	file_delete, /allow, /quiet, star_dir + 'ext_var.idl'
	@data_quality





	n_datapoints = n_elements(target_lc)
;COMP;	
	n_comparisons = n_elements(comparisons_lc[0,*])

	; check for bad points
	if n_datapoints lt 10 then return

	; ...determine scatter out/in focus, identify points with too many outliers among comparisons
	i_outliers = bytarr(n_elements(target_lc))
;COMP;	
	i_outoffocus = where(target_lc.hjd lt 55500, n_outoffocus)
	if n_outoffocus gt 0 then begin
		oof_comparisons_scatter = (fltarr(n_outoffocus)+1)#(1.48*median(abs(comparisons_lc[i_outoffocus, *].flux), dimen=1))
		if n_comparisons gt 1 then oof_outliers = total(abs(comparisons_lc[i_outoffocus, *].flux) gt n_sigma_comparisons*oof_comparisons_scatter, 2) else oof_outliers = comparisons_lc[i_outoffocus, *].flux gt n_sigma_comparisons*oof_comparisons_scatter
		i_too_outlying = where(oof_outliers gt n_outlier_fraction*n_comparisons, n_too_outlying)
		if n_too_outlying gt 0 then i_outliers[i_outoffocus[i_too_outlying]] = 1B
	endif

	i_infocus = where(target_lc.hjd lt 55500, n_infocus)
	if n_infocus gt 0 then begin
		inf_comparisons_scatter = (fltarr(n_infocus)+1)#(1.48*median(abs(comparisons_lc[i_infocus, *].flux), dimen=1))
		if n_comparisons gt 1 then inf_outliers = total(abs(comparisons_lc[i_infocus, *].flux) gt n_sigma_comparisons*inf_comparisons_scatter, 2) else inf_outliers = comparisons_lc[i_infocus, *].flux gt n_sigma_comparisons*inf_comparisons_scatter
		i_too_outlying = where(inf_outliers gt n_outlier_fraction*n_comparisons, n_too_outlying)
		if n_too_outlying gt 0 then i_outliers[i_infocus[i_too_outlying]] = 1B
	endif

	; .... too far of a radial offset in position on detector, or absolute in either x or y
	mispointing = fltarr(n_elements(ext_var)) + 999
	i_badpointing = bytarr(n_elements(ext_var))
	i_left = where(ext_var.merid eq 0.0, n_left)
	if n_left ge 1 then begin
		if n_left gt 1 then begin
			ext_var[i_left].left_xlc -= median(ext_var[i_left].left_xlc) 
			ext_var[i_left].left_ylc -= median(ext_var[i_left].left_ylc) 
		endif else begin
			ext_var[i_left].left_ylc = 0.0
			ext_var[i_left].left_xlc = 0.0
		endelse
		mispointing[i_left] = sqrt(ext_var[i_left].left_xlc^2 + ext_var[i_left].left_ylc^2)
		i_badpointing[i_left] = i_badpointing[i_left] or abs(ext_var[i_left].left_xlc) gt xy_limit or abs(ext_var[i_left].left_ylc) gt xy_limit
	endif
	i_right = where(ext_var.merid eq 1.0, n_right)
	if n_right ge 1 then begin
		if n_right gt 1 then begin
			ext_var[i_right].right_xlc -= median(ext_var[i_right].right_xlc) 
			ext_var[i_right].right_ylc -= median(ext_var[i_right].right_ylc) 
		endif else begin
			ext_var[i_right].right_ylc = 0.0
			ext_var[i_right].right_xlc = 0.0
		endelse
		mispointing[i_right] = sqrt(ext_var[i_right].right_xlc^2 + ext_var[i_right].right_ylc^2)
		i_badpointing[i_right] = i_badpointing[i_right] or abs(ext_var[i_right].right_xlc) gt xy_limit or abs(ext_var[i_right].right_ylc) gt xy_limit
	endif
	pixels_limit = 1.48*mad(mispointing)*pointing_limit;median(mispointing) + 
	i_badpointing = i_badpointing or (mispointing gt pixels_limit) 

	; .... too few points in a week (these tend to be useless!)		
	i_weekly_low_density = bytarr(n_elements(ext_var.mjd_obs))
	points_per_week = histogram(round(target_lc.hjd-0.292), bin=7, reverse_indices=ri)
	ri_weekly_low_density = where(points_per_week lt weekly_density_limit and points_per_week gt 0, n_low_density_weeks)
	for i=0, n_low_density_weeks-1 do i_weekly_low_density[ri[ri[ri_weekly_low_density[i]]:ri[ri_weekly_low_density[i]+1]-1]] = 1

	; .... too short of a night
	i_shortnight = bytarr(n_elements(ext_var.mjd_obs))

	; .... too few points in a night 
	i_daily_low_density = bytarr(n_elements(ext_var.mjd_obs))
	points_per_day = histogram(round(target_lc.hjd-0.292), bin=1, reverse_indices=ri)
	for i=0, n_elements(points_per_day)-1 do begin
		if points_per_day[i] gt 0 then begin
			i_night_start = ri[ri[i]]
			i_night_end = ri[ri[i+1]-1]
			if points_per_day[i] lt daily_density_limit then begin
				i_daily_low_density[i_night_start:i_night_end] = 1
			endif
			if ext_var[i_night_end].mjd_obs - ext_var[i_night_start].mjd_obs lt short_night_limit then begin
				i_shortnight[i_night_start:i_night_end] = 1
			endif
		endif
	endfor

	; .... that week in December when everything went screwy		
	if ~keyword_set(baddatesokay) then begin
		i_date = (ext_var.mjd_obs gt 54815 and ext_var.mjd_obs lt 54832)
		i_date = i_date or (ext_var.mjd_obs gt 55670 and ext_var.mjd_obs lt 55671)
	endif else i_date = bytarr(n_elements(ext_var.mjd_obs))
	tel_filename = 'tel'+ stregex(stregex(star_dir, /ex, 'te[0-9]+'), /ex, '[0-9]+')+'.bad.dates'
	if file_test(tel_filename) then begin
		openr, dates_lun, tel_filename, /get_lun
		date_start = ' '
		date_end =  ' ' 
		while(~eof(dates_lun)) do begin
			readf, dates_lun, date_start, date_end, format='(2A11)'
			mjd_start = date_conv(date_start, 'M')
			mjd_end = date_conv(date_end, 'M')
			i = where(ext_var.mjd_obs ge mjd_start and ext_var.mjd_obs le mjd_end, n_date)
			if n_date gt 0 then i_date[i] = 1
		endwhile
	endif
	; ... points are flagged as no data or bad pixels or saturated (recently stopped ignoring saturation flag, 2/10/11)
	i_flagged = (ext_var.flags and 1) or (ext_var.flags and 2); or (ext_var.flags and 4) 		
	
	; ... cloudiest points
	i_extc = ext_var.extc - median(ext_var.extc) lt extc_limit;*1.48*mad(ext_var.extc)
;	i_extc = ext_var.extc - median(ext_var.extc) lt extc_limit; (median_filter(ext_var.mjd_obs, ext_vsar.extc, filtering_time=observatory_change_time) lt extc_limit)

	; ... most elliptical points
	i_ellipticity = ext_var.ellipticity gt ellipticity_limit

	; ... most elliptical points
	i_sky = ext_var.sky gt sky_limit

	; ... most elliptical points
	i_peak = ext_var.peak gt peak_limit

	; censorship
	i_censored =bytarr(n_elements(ext_var.mjd_obs))
	ls_dir = stregex(star_dir, 'ls[0-9]+', /ext) + '/'
	censor_files = [file_search(ls_dir + '{*,*/*}/censorship.log'), file_search(ls_dir + '{*,*/*}/xlc_*_censorship.log')]
	mprint, tab_string, doing_string, 'censoring data based on comments in:'

	for i_file=0, n_elements(censor_files)-1 do begin
		mprint, tab_string, tab_string, censor_files[i_file]
;		print, 'censoring datapoints marked in', censor_files[i_file]
		if censor_files[i_file] eq '' then continue
		openr, censor_lun, /get_lun, censor_files[i_file]
		hjd =0.0d
		text = ' '
		while(~eof(censor_lun)) do begin
			readf, censor_lun, hjd, text
;			print, 'trying to censor ', hjd
			i = where(abs(target_lc.hjd - hjd) le censorship_size/2.0, n_censor)
			if n_censor gt 0 then begin
				i_censored[i] = 1
;				print, 'censored ', n_censor, ' data points'
			endif; else print, 'failed!'
			
		endwhile
		close, censor_lun
	endfor

; raw_censorship
	i_raw_censored =bytarr(n_elements(ext_var.mjd_obs))
	censor_files = file_search(ls_dir + '{*,*/*}/raw_image*censorship.log')

	if censor_files[0] ne '' then begin
		for i_file=0, n_elements(censor_files)-1 do begin
			mprint, tab_string, tab_string, censor_files[i_file]
			openr, raw_censor_lun, /get_lun, censor_files[i_file]		
			hjd =0.0d
			text = ' '
			while(~eof(raw_censor_lun)) do begin
				readf, raw_censor_lun, hjd, text
				i = where(abs(target_lc.hjd - hjd) le raw_censorship_size, n_raw_censor)
				if n_raw_censor gt 0 then begin
				;	i = i[sort(abs(target_lc[i].hjd - hjd))]
					i_raw_censored[i] = 1;[0]] = 1
					print, hjd, i;[0]
				endif
			endwhile
			close, raw_censor_lun
		endfor
	endif
; CENSORSHIP WILL CURRENTLY SQUASH ALL DATA POINTS WITHIN A GIVEN TIME WINDOW! DOESN'T ACCOUNT FOR MULTIPLE TELESCOPES IDEALLY!


	; ... large internal scatter
	;rms_filtered = median_filter(ext_var.mjd_obs, ext_var.rms, filtering_time=observatory_change_time) 
	i_rms = (ext_var.rms - median(ext_var.rms)) gt rms_limit*1.48*mad(ext_var.rms)

	; ... target star is NaN
	i_nan = finite(/nan, target_lc.flux)											



	if keyword_set(trimtransits) then begin
		restore, star_dir + 'cleaned_lc.idl'
		i_intransit = bytarr(n_elements(target_lc.hjd))
		indices_intransit = where_intransit(target_lc, candidate, buffer=20.0/60.0/24.0, n_intransit)
		if n_intransit gt 0 then i_intransit[indices_intransit] = 1
	endif


;	i_jupiter = abs(target_lc.flux*(lspm_info.radius*109.04501)^2) gt radius_limit^2

; 	; .... fluxerr is very, very large
; 	fluxerr_filtered = median_filter(ext_var.mjd_obs, target_lc.fluxerr, filtering_time=observatory_change_time) 
; 	i_error = fluxerr_filtered gt error_limit*1.48*mad(fluxerr_filtered) 

	; ... if the star is blended, throw out bad seeing points!
	seeing_filtered = ext_var.see - median(ext_var.see); median_filter(ext_var.mjd_obs, ext_var.see, filtering_time=observatory_change_time) 
	i_seeing = ((abs(seeing_filtered) gt seeing_limit*1.48*mad(seeing_filtered)) AND ext_var.bflag eq 1) or ext_var.see lt 2.0

	; ... combine them all together
	i_bad = i_flagged or i_extc or i_rms or i_nan or i_outliers or i_daily_low_density or i_weekly_low_density or i_shortnight or i_badpointing or i_seeing or i_date  or i_ellipticity or i_sky or i_peak or i_censored or i_raw_censored; or i_error
	

	i_bandwagon = mean_smooth(target_lc.hjd, i_bad, filtering_time=bandwagon_time) gt bandwagon_limit
	n_bandwagon = total(i_bandwagon gt 0 or i_bad gt 0, /int) - total(i_bad gt 0, /int)
	i_bad = i_bad or i_bandwagon
	if keyword_set(trimtransits) then i_bad = i_bad or i_intransit

	i_good = i_bad eq 0



	if keyword_set(allow_all) then begin
		 i_good = indgen(n_datapoints)
 		print, 'WATCH OUT! allowing all data, regardless of quality!'
	endif else begin
	endelse

	mask = where(i_nan, n_nan)
	if n_nan gt 0 then begin
		target_lc[mask].flux = 0.0
		target_lc[mask].fluxerr = 0.0
	endif
	mprint,tab_string,' discarding ', strcompress(/remove_all, string(format='(I)', total(i_bad gt 0))), ' of ',strcompress(/remove_all, string(format='(I)', n_datapoints)) ,' raw points:';for the following reasons:<i>'

	n_rejected = {flag:total(i_flagged ne 0, /int), extc:total(i_extc ne 0, /int), rms:total(i_rms ne 0, /int), nan:total(i_nan ne 0, /int), outliers:total(i_outliers ne 0, /int), i_daily_low_density:total(i_daily_low_density ne 0, /int), weekly_low_density:total(i_weekly_low_density ne 0, /int), shortnight:total(i_shortnight ne 0, /int), badpointing:total(i_badpointing ne 0, /int), seeing:total(i_seeing ne 0, /int), date:total(i_date ne 0, /int),  ellipticity:total(i_ellipticity ne 0, /int),  sky:total(i_sky ne 0, /int),  peak:total(i_peak ne 0, /int),   censored:total(i_censored ne 0, /int),  raw_image_censored:total(i_raw_censored ne 0, /int), bandwagon:n_bandwagon}
	tags = tag_names(n_rejected) 
	for i=0, n_tags(n_rejected) -1 do mprint, tab_string,string(form='(A20)', tags[i]), string(form='(I5)', n_rejected.(i))

	target_lc.okay = i_good
	save, filename=star_dir + 'raw_target_lc.idl', target_lc
	if total(i_bad) gt 0 then begin
		bad_mjd = ext_var[where(i_bad)].mjd_obs
		save, filename=star_dir + 'bad_mjd.idl', bad_mjd
	endif	
	if total(i_good) gt 0 then begin
		good_mjd = ext_var[where(i_good)].mjd_obs
		save, filename=star_dir + 'good_mjd.idl', good_mjd
	endif
	save, filename=star_dir + 'raw_trimmed.idl', n_rejected, n_datapoints

END