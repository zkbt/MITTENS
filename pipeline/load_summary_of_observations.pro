PRO load_summary_of_observations, ensemble_observation_summary=ensemble_observation_summary
	
	common mearth_tools
	mprint, doing_string, 'loading observation summaries into population/ensemble_observation_summary.idl'
	f = file_search('ls*/ye*/te*/observation_summary.idl')
	
	for i=0, n_elements(f)-1 do begin
		mprint, tab_string, tab_string, f[i]
		restore, f[i]
		if n_elements(ensemble_observation_summary) eq 0 then begin
			ensemble_observation_summary = observation_summary
		endif else begin
			ensemble_observation_summary = [ensemble_observation_summary, observation_summary]
		endelse
	endfor
	save, ensemble_observation_summary, filename='population/ensemble_observation_summary.idl'
END