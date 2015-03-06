PRO summarize_filtering
	@constants
	@make_plots_thick
	!p.thick=6
	years = 2008 + findgen(5)
	jan_mjd = dblarr(n_elements(years))
	for i=0, n_elements(years)-1 do begin
		juldate, [years[i], 1, 1], jd_temp
		jan_mjd[i] = jd_temp
	endfor
	loadct, 39
	result = [file_search('stars/tel*lspm[0-9][0-9]/good_mjd.idl'),  file_search('stars/tel*lspm[0-9][0-9][0-9]/good_mjd.idl'),  file_search('stars/tel*lspm[0-9][0-9][0-9][0-9]/good_mjd.idl')]
	if not keyword_set(temp) then temp=300
	temp_string = 'TEFF'+strcompress(/remove_all, temp)+'K'
	one_target = {tel:0, lspm:0, ra:0.0, dec:0.0, stellar_radius:0.0, mearth_mag:0.0, variability:0.0, stellar_temperature:0.0, filtered_rms:0.0, planet_1sigma:0.0, unfiltered_planet_1sigma:0.0, hypothetical_planet_1sigma:0.0}
	cloud = replicate(one_target, n_elements(result))
    for i=0, n_elements(result)-1 do begin
		star_dir = strmid(result[i], 0, strpos(result[i], 'good_mjd.idl'))

		tel = uint(strmid(stregex(star_dir, 'tel[0-9]+', /extract), 3, 2))
		lspm = uint(strmid(stregex(star_dir, 'lspm[0-9]+', /extract), 4,4))
		info = get_lspm_info(lspm)
		print, star_dir
		cloud[i].tel = tel
		cloud[i].lspm = lspm
		cloud[i].stellar_radius = info.radius
		cloud[i].stellar_temperature = info.teff
		cloud[i].ra = info.ra/15.0
		cloud[i].dec = info.dec
		
		filename = star_dir + 'field_info.idl'
		if file_test(filename) then begin
			restore, filename
			cloud[i].mearth_mag = info_target.medflux
		endif

		restore, star_dir + 'target_lc.idl'
		if file_test(star_dir + 'medianed_lc.idl') then restore, star_dir + 'medianed_lc.idl'

	
			filename = star_dir + 'photometry.idl'
			if file_test(filename) then begin
	;			restore, filename
				cloud[i].variability = stddev(target_lc.flux);photometry[1].stddev
				if keyword_set(medianed_lc) then cloud[i].filtered_rms = stddev(medianed_lc.flux) else cloud[i].filtered_rms = 0; photometry[2].stddev
				cloud[i].planet_1sigma = (sqrt(cloud[i].filtered_rms)*cloud[i].stellar_radius)*r_solar/r_earth
				cloud[i].unfiltered_planet_1sigma = (sqrt(cloud[i].variability)*cloud[i].stellar_radius)*r_solar/r_earth
				cloud[i].hypothetical_planet_1sigma = (sqrt(mean(target_lc.fluxerr))*cloud[i].stellar_radius)*r_solar/r_earth
	
			endif
	endfor
	save, filename='filtering_summary.idl', cloud
END