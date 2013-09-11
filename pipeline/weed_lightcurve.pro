PRO weed_lightcurve, remake=remake, lenient=lenient, baddatesokay=baddatesokay, trimtransits=trimtransits
;+
; NAME:
;	weed_lightcurve
; PURPOSE:
;	weeds out data that's been flagged as bad, and bins light curves into exposures chunks.
; CALLING SEQUENCE:
;	weed_lightcurve
; INPUTS:
;	restore, star_dir + 'raw_target_lc.idl'
;	restore, star_dir + 'raw_comparisons_lc.idl'
;	restore, star_dir + 'raw_ext_var.idl'
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	save, filename=star_dir + 'target_lc.idl', target_lc
;	save, filename=star_dir + 'comparisons_lc.idl', comparisons_lc, comparisons_pointers
;	save, filename=star_dir + 'ext_var.idl', ext_var
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
	; skip this all, if not necessary	
	everything_upto_date = 1B
	ls_dir = stregex(star_dir(), 'ls[0-9]+', /ext) + '/'

	files_to_check =[ file_search(ls_dir + '{*,*/*}/raw_image_censorship.log'),  file_search(ls_dir + '{*,*/*}/censorship.log'),  file_search(ls_dir + '{*,*/*}/xlc_*_censorship.log'),  star_dir() + 'raw_ext_var.idl']
	for i=0, n_elements(files_to_check)-1 do if files_to_check[i] ne '' then everything_upto_date = everything_upto_date AND is_uptodate(star_dir() + 'target_lc.idl', files_to_check[i])

	;if (is_uptodate(star_dir + 'target_lc.idl', star_dir + 'raw_ext_var.idl') and is_uptodate(star_dir + 'target_lc.idl', star_dir + 'censorship.log') and is_uptodate(star_dir + 'target_lc.idl', star_dir + 'raw_image_censorship.log'))$
	;	or is_uptodate(star_dir + 'last_reprocessed.txt', star_dir + 'raw_ext_var.idl') eq 0$
	if everything_upto_date	and ~keyword_set(remake) then begin
	 		mprint, skipping_string, 'light curve weeding is up to date!'
	 		return
	endif

	mprint, doing_string, 'weeding light curve for ', star_dir
	flag_bad_data, lenient=lenient, baddatesokay=baddatesokay, trimtransits=trimtransits
	restore, star_dir + 'raw_target_lc.idl'
	restore, star_dir + 'raw_comparisons_lc.idl'
	restore, star_dir + 'raw_ext_var.idl'
	starttime = systime(/sec)
	

	; if all data are bad, delete (previous) weeded light curves
	if total(target_lc.okay) eq 0 then begin
		file_delete, star_dir + 'target_lc.idl', /allow
		file_delete, star_dir + 'comparisons_lc.idl', /allow
		file_delete, star_dir + 'ext_var.idl', /allow
		file_delete, star_dir + 'box_pdf.idl', /allow

	endif
	
	i=0
	counter = 0
	n = n_elements(ext_var)
	new_target_lc = target_lc
	
new_comparisons_lc = comparisons_lc
	new_ext_var = ext_var

	n_exposures = n_elements(target_lc)
	n_goodexposures = total(target_lc.okay ne 0, /int)

 ; mprint, string(format='(I10)', n), ' total raw datapoints '
 ; mprint, string(format='(I10)',total(target_lc.okay gt 0)), ' acceptable raw datapoints'

	while i lt n do begin
		i_thischunk = i
		iexp_thischunk = ext_var[i].iexp
		for j=1, ext_var[i].nexp-1 do begin
			if i+j lt n_elements(ext_var) then begin
				if ext_var[i+j].iexp gt ext_var[i+j-1].iexp and (ext_var[i+j].mjd_obs - ext_var[i+j-1].mjd_obs)*24*60*60 lt (ext_var[i+j].exptime + 90.0)*(ext_var[i+j].iexp - ext_var[i+j-1].iexp) then begin
					if ext_var[i+j].iexp gt iexp_thischunk[j-1] then begin
						i_thischunk = [i_thischunk, i+j]
						iexp_thischunk = [iexp_thischunk, ext_var[i+j].iexp]
					endif
				endif else break
			endif
		endfor
 	;	print, iexp_thischunk
 	;	print, i_thischunk

		weights = double(mean(target_lc[i_thischunk].fluxerr^2)/target_lc[i_thischunk].fluxerr^2*target_lc[i_thischunk].okay)
;		weights = double(target_lc[i_thischunk].okay)


		if total(weights) gt 0 then begin
			i_okay = where(weights gt 0, n_okay)
			if total(weights gt 0) ge 3 then begin
				not_outlier = abs(target_lc[i_okay].flux - median(target_lc[i_okay].flux)) lt 5.0*1.48*mad(target_lc[i_okay].flux)
				weights[i_okay] *= not_outlier
				i_okay = where(weights gt 0, n_okay)
			endif

			if n_okay ge 1 then begin
				new_target_lc[counter] = bin_struct_array(target_lc[i_thischunk], weights=weights)
				new_target_lc[counter].fluxerr /= sqrt(n_okay)
	

				if n_elements(comparisons_lc[*,0]) eq n_elements(target_lc) then begin
					for j=0, n_elements(comparisons_lc[0,*]) -1 do begin
						new_comparisons_lc[counter, j] = bin_struct_array(comparisons_lc[i_thischunk, j],weights=weights)
						new_comparisons_lc[counter, j].fluxerr /= sqrt(n_okay)
					endfor
				endif else no_comparisons = 1	
				new_ext_var[counter] = bin_struct_array(ext_var[i_thischunk],weights=weights)
	
				if finite(/nan, new_target_lc[counter].flux) then help
				counter += 1

			endif
		endif
		i += n_elements(i_thischunk)
	endwhile
	if counter ge 1 then begin
		target_lc = new_target_lc[0:counter-1]
		if ~keyword_set(no_comparisons) then comparisons_lc = new_comparisons_lc[0:counter-1, *]	
		ext_var = new_ext_var[0:counter-1]
	
		wait, 0.1 + (systime(/sec) - starttime) 

		save, filename=star_dir + 'target_lc.idl', target_lc
		if ~keyword_set(no_comparisons) then save, filename=star_dir + 'comparisons_lc.idl', comparisons_lc, comparisons_pointers
		save, filename=star_dir + 'ext_var.idl', ext_var

		ls = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))	
		ye = long(stregex(/ext, stregex(/ext, star_dir, 'ye[0-9]+'), '[0-9]+'))
		te = long(stregex(/ext, stregex(/ext, star_dir, 'te[0-9]+'), '[0-9]+'))
		observation_summary = {star_dir:star_dir, ls:ls[0], ye:ye[0], te:te[0], n_exposures:n_exposures, n_goodexposures:n_goodexposures, n_observations:n_elements(target_lc), n_nights:n_elements(uniq(mjdtohopkinsnight(ext_var.mjd_obs), sort(ext_var.mjd_obs))), startnight:min(mjdtohopkinsnight(ext_var.mjd_obs)), endnight:max(mjdtohopkinsnight(ext_var.mjd_obs))}
		
		save, observation_summary, filename=star_dir + 'observation_summary.idl'
		mprint, tab_string, 'after squashing, ', strcompress(/remo, n_elements(target_lc)), ' points remain'
	endif

	mprint, done_string
END

