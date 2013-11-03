PRO plot_hankasalmi, events=events

	files = file_search('/pool/barney0/jirwin/mearth/lspm2986/hankasalmi/*/lc.fits')
	for i_file=0, n_elements(files)-1 do begin
		filename = files[i_file]
		print, filename
		m = mrdfits(filename, 1, h)
		theta = findgen(21)/20*2*!pi
		usersym, cos(theta), sin(theta)
	
		fi = file_info(filename)
	
		if fi.exists ne 0 and fi.size ne 0 then begin
			fits_lc = mrdfits(filename, 1, header_lc, status=status, /silent)
			; if successfully read in, then continue to generate an IDL lightcurve		
			if status eq 0 then begin
				print,  ' extracting all M dwarf light curves from ', filename
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
					ext_var.mjd_obs = sxpar(header_lc, 'MJDBASE') + jxpar(header_lc, 'TV*', n_array)
					ext_var.exptime = jxpar(header_lc, 'TEXP*', n_array)
					; these variables have sometimes not had values for all time points - jxpar will double check that before reading!
	
					big_ext_var = ext_var
	
	
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
			
						; throw out the tiny by with bad old filters at the star of the 2010-2011 season
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
								
	; 						openw, f, star_dir + 'make_lightcurve.txt', /get_lun, width=200
							print, '      M dwarf #', strcompress(/remo, j), ' going into ', star_dir
						
							my_file = file_info(star_dir + 'raw_ext_var.idl')
							j_file = file_info(jmi_file_prefix + '_lc.fits')
							if my_file.mtime le j_file.mtime or keyword_set(remake) then begin
							
								; create PNG of field image
							;	make_field_image, star_dir, jmi_file_prefix, old=old
						
								if n_datapoints gt 0 then begin
						
									; define the set of stars that is not the target star
									i_comparisons = where((fits_lc.class eq -1 or (fits_lc.class eq 9 and fits_lc.pointer ne fits_lc[i_target].pointer)) and fits_lc.medflux lt fits_lc[i_target].medflux+2.5, n_comparisons);and total(finite(/nan, fits_lc.flux), 1) lt (0.75*n_datapoints > 1) 
									limiting_mag_offset = 2.5
						
									; push down to fainter comparisons if there aren't enough bright ones
									while (n_comparisons eq 0) and (limiting_mag_offset) lt 10 do begin
										limiting_mag_offset += 0.5
										i_comparisons = where((fits_lc.class eq -1 or (fits_lc.class eq 9 and fits_lc.lspm ne fits_lc[i_target].lspm))  and fits_lc.medflux lt fits_lc[i_target].medflux+ limiting_mag_offset, n_comparisons); and total(finite(/nan, fits_lc.flux), 1) lt (0.75*n_datapoints > 1)
									endwhile
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
	
	
									star_dir = '/pool/eddie1/zberta/mearth_most_recent/ls2986/ye11/te12/'
									file_mkdir, star_dir
									; select only this year, and save
									target_lc = target_lc[where(years eq year[i_year])]
									ext_var = ext_var[where(years eq year[i_year])]
									print, '          ', strcompress(/remo, n_elements(target_lc)), ' raw photometry points'
								endif
							endif else print, '         lightcurve already made, not remaking'
						endfor
					endfor
				endif
			endif else print, " :-0 couldn't read " + filename
		endif else print, " :-0 couldn't read " + filename


		if n_elements(combined_target_lc) eq 0 then combined_target_lc = target_lc else combined_target_lc = [combined_target_lc, target_lc]
		if n_elements(combined_ext_var) eq 0 then combined_ext_var = ext_var else combined_ext_var = [combined_ext_var, ext_var]

	endfor

	target_lc = combined_target_lc
	ext_var = combined_ext_var

	save, target_lc, filename=star_dir + 'raw_' + 'target_lc.idl'
	save, ext_var, filename=star_dir + 'raw_' + 'ext_var.idl'
	file_copy, '/pool/eddie1/zberta/mearth_most_recent/ls2986/ye08/te08/sfit.idl', star_dir, /over

	restore, '/pool/eddie1/zberta/mearth_most_recent/ls2986/combined/candidates_pdf.idl'

	
	tags = tag_names(ext_var)
	tagstoplot = ['LEFT_XLC', 'LEFT_YLC', 'PEAK', 'SEE', 'EXTC', 'SKY']
	labels       = ['X', 'Y', 'PEAK', 'SEEING', 'EXTC', 'SKY']


	set_plot, 'ps'
	device, filename='hanksalmi_lc.eps', /encapsulated, /color, xsize=10, ysize=7, /inches
	
	!p.charsize=0.6
	!p.symsize=0.5
	!y.ticklen=0.01
	!x.style = 3
	erase
	n_extra = n_elements(tagstoplot)
	smultiplot, [1,n_extra+1], rowh=[1,0.3*ones(n_extra)], /init, ygap=0.01
	smultiplot
	hjd = target_lc.hjd + 2400000.5d
	loadct, 39
	!x.range =[max(hjd)-0.25, max(hjd)] ; - 0.3,
	!x.style=3
	plot, hjd, target_lc.flux, psym=8, yr=[0.02, -0.02], xtickunits='Hours', xcharsize=0.01, symsize=!p.symsize, ytitle='Relative Flux (mag.)'
	x = min(!x.range) + findgen(10000)*(max(!x.range) - min(!x.range))/10000.0

;	restore, '/pool/eddie1/zberta/mearth_most_recent/ls2986/combined/predictions/2012090.6_05.9435355_0.030.idl'
;	restore, '/pool/eddie1/zberta/mearth_most_recent/ls2986/combined/predictions/2012090.6_02.9717646_0.030.idl'
;	decent = decent[where(decent.depth/decent.depth_uncertainty gt 6.5)]
;
	restore, '/pool/eddie1/zberta/mearth_most_recent/ls2986/combined/candidates_pdf.idl'
	decent = best_candidates[0]
	for i=0, 40-1 do begin
		
		candidate = decent[randomu(seed)*n_elements(decent)]
;	for i=0, n_elements(best_candidates)-1 do begin
; 	i =3
; 		candidate = best_candidates[i]
		candidate.hjd0 += 2400000.5d

		this_event = round((max(hjd) - candidate.hjd0)/candidate.period)
		oplot, x, candidate.depth*(abs((x-this_event*candidate.period - candidate.hjd0)) le candidate.duration/2.0), color=250, linestyle=(candidate.depth/candidate.depth_uncertainty lt 7.0)
;		xyouts, this_event*candidate.period + candidate.hjd0,  candidate.depth, '!C'+rw(i), color=250, align=0.5
;
	endfor

	for i=0, n_extra-1 do begin
		j = where(tags eq tagstoplot[i])
		smultiplot
		if i eq n_extra-1 then begin
			xtitle='Hours UT'
		endif else xtitle=' '
		plot, psym=8, hjd, ext_var.(j), ytitle=labels[i], yno=(tagstoplot[i] ne 'EXPTIME'), xtickunits='Hours', xcharsize=0.01 + 0.99*(i eq n_extra-1), xtitle=xtitle, symsize=!p.symsize
	endfor
	smultiplot, /def

	device, /close
	epstopdf, 'hanksalmi_lc.eps'
	target_lc.okay = target_lc.fluxerr lt 0.005 and target_lc.hjd gt 56018.8d

	i = where(target_lc.okay)
	target_lc = target_lc[i]
	save, target_lc, filename=star_dir + 'target_lc.idl'
	ext_var = ext_var[i]
	save, ext_var, filename=star_dir + 'ext_var.idl'

	inflated_lc = target_lc
	inflated_lc.flux -= median(inflated_lc.flux)
	inflated_lc.fluxerr *=sqrt(total((inflated_lc.flux/inflated_lc.fluxerr)^2)/(n_elements(inflated_lc)-1))

	save, inflated_lc, filename=star_dir + 'inflated_lc.idl'

	boxes = generate_boxes(inflated_lc)
	for i=0, n_elements(boxes)-1 do begin
		for j=0, n_elements(boxes[0].duration)-1 do begin
			i_intransit = where(abs(inflated_lc.hjd - boxes[i].hjd) lt boxes[i].duration[j]/2.0, n)
			if n gt 0 then begin
				boxes[i].n[j] = n
				lc = inflated_lc[i_intransit]
				boxes[i].depth[j] = total(lc.flux/lc.fluxerr^2)/total(1.0/lc.fluxerr^2)
				boxes[i].depth_uncertainty[j] = sqrt(1.0/total(1.0/lc.fluxerr^2))
			endif	
		endfor
	endfor
	stop
	save, boxes, filename=star_dir + 'box_pdf.idl'
	cleanplot, /sil
	xplot, xsize=1000, ysize=400
	plot_boxes, boxes
	print_struct, target_lc
	print_struct, inflated_lc

END	