PRO run_make_lspm_directory
	; need a reduced data directory for each year
	possible_years = [2008,2009,2010,2011]
	reduced_dir = ['/data/mearth2/2008-2010-iz/reduced/','/data/mearth2/2008-2010-iz/reduced/', '/data/mearth2/2010-2011-I/reduced/', '/data/mearth1/reduced/']
	yearly_filters = ['iz', 'iz', 'I', 'iz']
	
	; set working directory; on CfA network or on laptop?
	;if getenv('HOME') eq '/Users/zachoryberta' then working_dir = '/Users/zachoryberta/mearth/' else 
	working_dir = '/pool/eddie1/zberta/mearth_test/'
	remake=1
	old=1
	all = 1
	; figure out whether loading just one or all of the stars
	if not keyword_set(desired_lspm) then all = 1
	if keyword_set(all) then begin
		lspm = '*' 
		search_string = 'lspm*'
	endif else begin
		lspm = desired_lspm + indgen(5)-2
		search_string = 'lspm'+strcompress(/remo, lspm)
	endelse


	; loop over the possible years
	if keyword_set(old) then k_start = 0 else k_start = n_elements(possible_years)-1
	for k=k_start, n_elements(possible_years)-1 do begin
		year = possible_years[k]	
		tel_string = 'tel0*'
		dir = reduced_dir[k] + tel_string + '/master/'
		jmi_this_year = file_search(dir + search_string +'_lc.fits')

		; loop through fields available this year
		for i=0, n_elements(jmi_this_year)-1 do begin
			; figure out what the MITTEN filename of the first M dwarf in the field would be called
			tel = long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'tel[0-9]+'), '[0-9]+'))
			lspm =  long(stregex(/ex, stregex(/ex, jmi_this_year[i], 'lspm[0-9]+'), '[0-9]+'))
			mitten_filename = make_star_dir(lspm, year, tel)+'raw_ext_var.idl'
			; if it's not up-to-date, load the light curves
	;		if is_uptodate(mitten_filename, jmi_this_year[i]) eq 0 or keyword_set(remake) then begin	
;				if question(jmi_this_year[i],/int) then stop
				make_lspm_directory, jmi_this_year[i], remake=remake
	;		endif else mprint, skipping_string, ' raw lightcurves in ', jmi_this_year[i], ' are up to date! '
		endfor
	endfor
END