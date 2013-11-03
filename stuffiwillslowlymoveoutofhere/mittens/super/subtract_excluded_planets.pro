FUNCTION subtract_excluded_planets, input_stars

	excluded = input_stars
	for i_mode=0,1 do begin 
		for i=0, n_elements(excluded)-1 do begin
			excluded[i].(i_mode).period_detection = 0.0
			excluded[i].(i_mode).temp_detection = 0.0
		endfor
	endfor

	; build up how many planets we've excluded
	f = file_search('budget_*.idl')
	for i_year=0, n_elements(f)-1 do begin
		restore, f[i_year]
		for i=0, n_elements(excluded)-1 do begin
			i_match = where(stars.obs.lspm eq excluded[i].obs.lspm, n_match)
			if n_match gt 0 then begin
				if n_match gt 1 then i_match = i_match[where(stars[i_match].phased_ps600 eq max(stars[i_match].phased_ps600))]
				i_match = i_match[0]
				for i_mode=0,1 do begin 
					excluded[i].(i_mode).period_detection = stars[i_match].(i_mode).period_detection > excluded[i].(i_mode).period_detection
					excluded[i].(i_mode).temp_detection = stars[i_match].(i_mode).temp_detection > excluded[i].(i_mode).temp_detection
				endfor
			endif
		endfor
	endfor

	; subtract those planets off from 
	stars = input_stars
	for i=0, n_elements(stars)-1 do begin
		for r=0, n_elements(stars[0].(0).period_detection[0,*])-1 do begin
			period_excluded_existing_transits = excluded[i].phased.period_detection[*,r]/excluded[i].phased.period_transitprob
			temp_excluded_existing_transits = excluded[i].phased.temp_detection[*,r]/excluded[i].phased.temp_transitprob
		
			for i_mode=0,1 do begin 
				stars[i].(i_mode).period_detection[*,r] *= (1.0 - period_excluded_existing_transits)
				stars[i].(i_mode).temp_detection[*,r] *= (1.0 - temp_excluded_existing_transits)

				i_temp300 = where(abs(real_phased_sensitivity.temp.grid - 300) lt 25)
				i_temp600 = where(abs(real_phased_sensitivity.temp.grid - 600) lt 25)

				stars[i].phased_ps300[r] = mean(stars[i].phased.temp_detection[i_temp300,r]) > 0
				stars[i].phased_ps600[r] = mean(stars[i].phased.temp_detection[i_temp600,r]) > 0
				stars[i].triggered_ps300[r] = mean(stars[i].triggered.temp_detection[i_temp300,r]) > 0
				stars[i].triggered_ps600[r] = mean(stars[i].triggered.temp_detection[i_temp600,r]) > 0

		
			endfor
		endfor
	endfor
	return, stars
END