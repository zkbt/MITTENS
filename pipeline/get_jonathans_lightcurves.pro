PRO get_jonathans_lightcurves, filename, remake=remake
;+
; NAME:
;	GET_JONATHANS_LIGHTCURVES
; PURPOSE:
;	take one of Jonathan's files, load all the M dwarf light curves in it into MITTENS (this function is called by load_star.pro)
; CALLING SEQUENCE:
;	get_jonathans_lightcurves, filename, remake=remake
; INPUTS:
;	filename = the (absolute) filename of one of Jonathan's light curve files
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	writes lots of files to MITTENS directories
; RESTRICTIONS:
; EXAMPLE:
;	get_jonathans_lightcurves, "/data/mearth2/2008-2010-iz/reduced/tel01/master/lspm1186_lc.fits', remake=remake
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

	common mearth_tools

	; read in FITS
	fi = file_info(filename)

	if fi.exists ne 0 and fi.size ne 0 then begin
		fits_lc = mrdfits(filename, 1, header_lc, status=status, /silent)
		; if successfully read in, then continue to generate an IDL lightcurve		
		if status eq 0 then begin
			mprint, doing_string, ' extracting all M dwarf light curves from ', filename
			jmi_file_prefix = strmid(filename, 0, strpos(filename, '_lc.fits'))
			start = stregex(jmi_file_prefix, '(lspm[0-9]+)+', length=length)
			lspm_section = strmid(jmi_file_prefix, start, length)
			anything_left = strmid(jmi_file_prefix, start + length, 1000)
			tel = uint(stregex(stregex(filename, 'tel[0-9]+', /extract), '[0-9]+', /extract))
	
		
			if anything_left ne '' then suffix = anything_left else suffix = '' 
	
			if n_elements(fits_lc[0].flux) gt 1 then begin

				; define an array containing the relevant external variables
				n_array = n_elements(fits_lc[0].hjd)
				ext_var = replicate({external_variable}, n_array)
				ext_var.off = jxpar(header_lc, 'OFF*', n_array)
				ext_var.rms = jxpar(header_lc, 'RMS*', n_array)
				ext_var.extc = jxpar(header_lc, 'EXTC*', n_array)
				ext_var.see = jxpar(header_lc, 'SEE*', n_array)
				ext_var.ellipticity = jxpar(header_lc, 'ELL*', n_array)
				ext_var.sky = jxpar(header_lc, 'SKY*', n_array)
				ext_var.sky_noise = jxpar(header_lc, 'NOIS*', n_array)
				ext_var.merid = jxpar(header_lc, 'IANG*', n_array)
				ext_var.iexp = jxpar(header_lc, 'IEXP*', n_array)
				ext_var.nexp = jxpar(header_lc, 'NEXP*', n_array)

				ext_var.spri = jxpar(header_lc, 'SPRI*', n_array)
				ext_var.scad = jxpar(header_lc, 'SCAD*', n_array)
				ext_var.styp = jxpar(header_lc, 'STYP*', n_array)
				ext_var.idat = jxpar(header_lc, 'IDAT*', n_array)
				ext_var.iupd = jxpar(header_lc, 'IUPD*', n_array)

				ext_var.mjd_obs = sxpar(header_lc, 'MJDBASE') + jxpar(header_lc, 'TV*', n_array)
				ext_var.exptime = jxpar(header_lc, 'TEXP*', n_array)
				; these variables have sometimes not had values for all time points - jxpar will double check that before reading!
				ext_var.skytemp = jxpar(header_lc, 'TSKY*', n_array)
				ext_var.humidity = jxpar(header_lc, 'HUM*', n_array)
				ext_var.pressure = jxpar(header_lc, 'PRES*', n_array)
				ext_var.iver = jxpar(header_lc, 'IVER*', n_array, error=error)
				ext_var.iseg = jxpar(header_lc, 'ISEG*', n_array, error=error)
				if error then ext_var.iseg = ext_var.merid+1
				big_ext_var = ext_var

				astonly = sxpar(header_lc, 'ASTONLY')
				; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				; N.B. - the external variables specific to each star in the field are defined later 
				; %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
				
				; pick out the M dwarf targets from the field
				i_targets = where(fits_lc.class eq 9, n_targets)
					
				; make and store lightcurves for every LSPM in the field
				for j=0, n_targets-1 do begin
					i_target = i_targets[j]

					; how long a lightcurve?
					n_datapoints =  n_elements(fits_lc[i_target].hjd)
				
					; set up directories and prefixes
					if not keyword_set(suffix) then suffix=''
					if keyword_set(allow_all) then suffix += '_untrimmed'
					if total(strmatch(tag_names(fits_lc), 'LSPM')) eq 0 then begin
						lspm_string = stregex(jmi_file_prefix, 'lspm[0-9]+', /extract) 
					endif else begin
						lspm_string = 'lspm' + strcompress(/remove_all, fits_lc[i_target].lspm)
					endelse
					lspm = long(stregex(lspm_string, '[0-9]+', /extract))
					tel_string = 'tel0'+strcompress(/remove_all, tel)
					tel = long(stregex(/ex, stregex(/ex, jmi_file_prefix, 'tel[0-9]+'), '[0-9]+'))

					; split up years! (split in late august)
					caldat, big_ext_var.mjd_obs + 2400000.5d  - 240.0d, months, days, years
					year = years[uniq(years)]
		
					; throw out the tiny bit with bad old filters at the star of the 2010-2011 season
					if strmatch(jmi_file_prefix, '*2008-2010-iz*') then year = year[where(year ne 2010)]

					for i_year=0, n_elements(year)-1 do begin
						
						ext_var = big_ext_var
						star_dir = make_star_dir(lspm, year[i_year], tel)
						if file_test(star_dir) eq 0 then file_mkdir, star_dir
						
						; to make it easier to look things up later....
						save, filename=star_dir + 'jmi_file_prefix.idl', jmi_file_prefix
						openw, f, star_dir + 'jmi_file_prefix.txt', /get_lun
						printf, f, jmi_file_prefix
						close, f
						free_lun, f
							
						if keyword_set(astonly) then begin
						openw, f, star_dir + 'astonly.txt', /get_lun
						printf, f, 'ASTONLY'
						close, f
						free_lun, f
						endif

; 						openw, f, star_dir + 'make_lightcurve.txt', /get_lun, width=200
						mprint, '      M dwarf #', strcompress(/remo, j), ' going into ', star_dir
					
						my_file = file_info(star_dir + 'raw_ext_var.idl')
						j_file = file_info(jmi_file_prefix + '_lc.fits')
						if my_file.mtime le j_file.mtime or keyword_set(remake) then begin
						
							; create PNG of field image
						;	make_field_image, star_dir, jmi_file_prefix, old=old
					
							if n_datapoints gt 0 then begin
								limiting_mag_offset = 2.5
					
								; define the set of stars that is not the target star
								i_comparisons = where((fits_lc.class eq -1 or (fits_lc.class eq 9 and fits_lc.pointer ne fits_lc[i_target].pointer)) and fits_lc.medflux lt fits_lc[i_target].medflux+limiting_mag_offset, n_comparisons);and total(finite(/nan, fits_lc.flux), 1) lt (0.75*n_datapoints > 1) 

								; push down to fainter comparisons if there aren't enough bright ones
								while (n_comparisons eq 0) and (limiting_mag_offset) lt 10 do begin
									limiting_mag_offset += 0.5
									i_comparisons = where((fits_lc.class eq -1 or (fits_lc.class eq 9 and fits_lc.lspm ne fits_lc[i_target].lspm))  and fits_lc.medflux lt fits_lc[i_target].medflux+ limiting_mag_offset, n_comparisons); and total(finite(/nan, fits_lc.flux), 1) lt (0.75*n_datapoints > 1)
								endwhile
								comparison_weights = median(fits_lc[i_comparisons].weight, dim=1)
								i_sorted_comps = reverse(sort(comparison_weights))
								i_comparisons = i_comparisons[i_sorted_comps[0:((n_elements(i_sorted_comps)-1) < 20)]]
							;	plot, fits_lc[i_comparisons].weight
								comparisons_pointers = fits_lc[i_comparisons].pointer
								
								; create structures to store time-independent information on every star in the field
								info_target = {field}
								copy_struct_inx, fits_lc, info_target, index_from=i_target
								info_comparisons = replicate({field}, n_comparisons)
								copy_struct_inx, fits_lc, info_comparisons, index_from=i_comparisons
								magzpt = sxpar(header_lc, 'MAGZPT')
								
								rcore = sxpar(header_lc, "RCORE")
								apradius = fits_lc[i_target].apradius
								aperture_size = rcore*apradius
								save, rcore, apradius, aperture_size, filename=star_dir + 'aperture.idl'
								save, info_target, info_comparisons, magzpt, filename=star_dir + 'field_info.idl'
	
								; save Jonathan's sine curve fit to the data
								tags = tag_names(fits_lc[i_target])
								new_sfit = 1
								for q = 0, n_elements(tags)-1 do begin
									if strmatch(tags[q], 'SFIT*') then begin
										if n_elements(sfit) eq 0 or new_sfit then begin
											sfit = create_struct(tags[q], fits_lc[i_target].(q)) 
											new_sfit = 0
										endif else sfit = create_struct(sfit, tags[q], fits_lc[i_target].(q))
									endif
								endfor

								copy_struct_inx, fits_lc, sfit, index_from=i_target
								save, sfit, filename=star_dir + 'sfit.idl'			
								if n_datapoints gt 1 then begin
									
									; define a lightcurve for the target star
									target_lc = replicate({lightcurve}, n_datapoints)
									target_lc.hjd = fits_lc[i_target].hjd
									target_lc.flux = fits_lc[i_target].flux
									target_lc.flux -= median(target_lc.flux)
									target_lc.fluxerr = fits_lc[i_target].fluxerr
									target_lc.okay = 1
									
; 									; define comparison star lightcurves
									comparisons_lc = replicate({lightcurve}, [n_datapoints, n_elements(i_comparisons)])
									comparisons_lc.hjd = fits_lc[i_comparisons].hjd
									comparisons_lc.flux = fits_lc[i_comparisons].flux
									comparisons_lc.flux -= (fltarr(n_datapoints)+1)#median(comparisons_lc.flux, dimen=1)
									comparisons_lc.fluxerr = fits_lc[i_comparisons].fluxerr
					
									; define the external variables for the target star
									ext_var.airmass = fits_lc[i_target].airmass
									ext_var.ha = fits_lc[i_target].ha
									i_left = where(ext_var.merid eq 0.0, n_left)
									i_right = where(ext_var.merid eq 1.0, n_right)
									if n_left gt 0 then begin
										ext_var[i_left].left_xlc = fits_lc[i_target].xlc[i_left]
										ext_var[i_left].left_ylc = fits_lc[i_target].ylc[i_left]
										if n_right gt 0 then begin
											ext_var[i_right].left_xlc = median([ext_var[i_left].left_xlc])
											ext_var[i_right].left_ylc = median([ext_var[i_left].left_ylc])
										endif
									endif
									if n_right gt 0 then begin
										ext_var[i_right].right_xlc = fits_lc[i_target].xlc[i_right]
										ext_var[i_right].right_ylc = fits_lc[i_target].ylc[i_right]
										if n_left gt 0 then begin
											ext_var[i_left].right_xlc = median([ext_var[i_right].right_xlc])
											ext_var[i_left].right_ylc = median([ext_var[i_right].right_ylc])
										endif
									endif		
									ext_var.bflag = fits_lc[i_target].bflag
									ext_var.flags = fits_lc[i_target].flags
									if total(strmatch(tag_names(fits_lc), 'PEAK')) gt 0 then ext_var.peak = fits_lc[i_target].peak
		
								endif

								; select only this year, and save
								target_lc = target_lc[where(years eq year[i_year])]
								save, target_lc, filename=star_dir + 'raw_' + 'target_lc.idl'
								comparisons_lc = comparisons_lc[where(years eq year[i_year]),*]
								save, comparisons_lc, comparisons_pointers, filename=star_dir + 'raw_' +  'comparisons_lc.idl'
								ext_var = ext_var[where(years eq year[i_year])]
								save, ext_var, filename=star_dir + 'raw_' + 'ext_var.idl'
								mprint, '          ', strcompress(/remo, n_elements(target_lc)), ' raw photometry points'
							endif
						endif else mprint, '         lightcurve already made, not remaking'
					endfor
				endfor
			endif
		endif else mprint, " :-0 couldn't read " + filename
	endif else mprint, " :-0 couldn't read " + filename

END
