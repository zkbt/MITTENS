PRO savetoascii
	common this_star
	common mearth_tools
	
	restore, star_dir() + 'inflated_lc.idl'
	restore, star_dir() + 'variability_lc.idl'
	restore, star_dir() + 'cleaned_lc.idl'
	restore, star_dir() + 'ext_var.idl'

	if n_elements(inflated_lc) ne n_elements(variability_lc) or n_elements(inflated_lc) ne n_elements(cleaned_lc) or n_elements(cleaned_lc) ne n_elements(variability_lc) then stop
	
	filename=star_dir() + 'lspm' + string(lspm_info.lspmn, form='(I04)') + '_mearth_lightcurve.ascii'
	openw, lun, filename, /get_lun

	que = "select * from nc where lspmn = "+ rw(string(form='(I)', lspm_info.lspmn))+";"
	sql = pgsql_query(que)
	printf, lun, '# MEarth identifier: lspm' + string(lspm_info.lspmn, form='(I04)')
	if n_tags(sql) gt 0 then begin
		printf, lun, '# LHS number: ' + rw(sql.lhs)
		printf, lun, '# NLTT number: ' + rw(sql.nltt)
		printf, lun, '# 2MASS identifier: J' + rw(sql.twomass)
		printf, lun, '# other names: ', sql.othname

		rah = long(double(sql.catra*180/!pi)/15)
		ram = long((double(sql.catra*180/!pi)/15 - rah)*60)
		ras = ((double(sql.catra*180/!pi)/15 - rah)*60 - ram)*60
		decd = long(double(sql.catdec*180/!pi))
		decm = long((double(sql.catdec*180/!pi) - decd)*60)
		decs = ((double(sql.catdec*180/!pi) - decd)*60-decm)*60
		pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)')

		printf, lun, '# RA, Dec = ' + pos_string
	endif
	printf, lun, '# file created: ', systime()
	printf, lun, '#'

	printf, lun, '# Notes on the Columns:'
	printf, lun, '# [1] Heliocentric MJD (= HJD - 2400000.5) at Mid-Exposure'
	printf, lun, '# [2] Basic MEarth Photometry (magnitudes, relative to median), '+STRING(13B)+'#     after differential photometry, but before decorrelation against external variables'
	printf, lun, '# [3] Decorrelated MEarth Photometry (mag.), after an attempt to '+STRING(13B)+'#     remove systematic trends via decorrelation, but meant to preserve stellar variability'
	printf, lun, '# [4] Cleaned MEarth Photometry (mag.), after removing both systematics '+STRING(13B)+'#     and night-to-night or sinusoidal variability'
	printf, lun, '# [5] Uncertainty Estimated for Basic MEarth Photometry (mag.), based on CCD noise model, '+STRING(13B)+'#     *before* accounting for additional noise due to systematics or variability'
	printf, lun, '# [6] Airmass of Observation'
	printf, lun, '# [7] FWHM of Stellar Images; '+STRING(13B)+'#     variations are due either to seeing or focus changes'
	printf, lun, '# [8] Estimated "Common Mode" correction for preciptable water vapor;'+STRING(13B)+'#     see Berta et al. (2012) for discussion'

	printf, lun, '#'
	printf, lun, '# Please contact Zach Berta (zberta@cfa.harvard.edu) with questions!'
	printf, lun, '#'


	for i=0, n_elements(inflated_lc)-1 do printf, lun, 	string(inflated_lc[i].hjd, form='(D13.6)') + $
									 	string(inflated_lc[i].flux, form='(D10.5)') + $
									 	string(variability_lc[i].flux, form='(D10.5)') + $
									 	string(cleaned_lc[i].flux, form='(D10.5)') + $
										string(inflated_lc[i].fluxerr, form='(D10.5)') + $
										string(ext_var[i].airmass, form='(D10.5)') + $
										string(ext_var[i].see, form='(D10.5)') + $
										string(ext_var[i].common_mode, form='(D10.5)')

	close, lun
	free_lun, lun
	spawn, 'kwrite ' + filename + '&'
END