PRO flag_ds9, xpa_name=xpa_name, image_filenames=image_filenames, flagged_in_ds9=flagged_in_ds9, image_hjds=image_hjds, censored_exposures=censored_exposures, censored_filenames=censored_filenames

	
	spawn, 'xpaget ' + xpa_name + ' file', image_flagged
	i_match = where(strmatch(image_filenames, image_flagged), n_match)
	if n_match eq 1 then begin
		i_match = i_match[0]
		if n_elements(censored_exposures) eq 0 then censored_exposures = image_hjds[i_match] else censored_exposures = [censored_exposures, image_hjds[i_match]] 
		if n_elements(censored_filenames) eq 0 then censored_filenames = image_filenames[i_match] else censored_filenames = [censored_filenames, image_filenames[i_match]] 

		if total(censored_exposures eq image_hjds[i_match]) mod 2 eq 0 then begin
			flagged = 0
		endif else flagged = 1
		if flagged then begin
			spawn, 'xpaset -p '+ xpa_name +' cmap Blue; xpaset -p '+ xpa_name +' cmap invert yes  '
		endif else begin
			spawn, 'xpaset -p '+ xpa_name +' cmap Grey; xpaset -p '+ xpa_name +' cmap invert yes  '
		endelse
		print, ' USING DS9 TO FLAG:'

	endif else print, ' UH-OH - could not match up images between ds9 and IDL'
END