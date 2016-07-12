FUNCTION load_custom_candidates
  ; load a custom candidate, stored in a text fill with a format of 
  ; "period hjd0 duration"
  ; which has a filename like mo*/combined/*.candidates
  ; and the code will populate the rest, based on the light curves
  
  ;load up star
  common this_star
  common mearth_tools

  ; make text displayed within this procedure is labeled
  procedure_prefix = '[load_custom_candidates]'

  ; figure out the filename
  filenames = file_search(star_dir() + '*.candidates')
  
  ; say what doing
  mprint, 'the following files will be loaded and searched for custom candidates'
  mprint, filenames
  
  ; loop over filenames
  for i=0, n_elements(filenames)-1 do begin
    f = filenames[i]
    readcol, f, periods, rawhjd0s, durations, format='D,D,F'
    for j=0, n_elements(periods) -1 do begin

      period = periods[j]
      rawhjd0 = rawhjd0s[j]
      duration = durations[j]
      mprint, "loaded candidate with"
      mprint, "  period = ", period
      mprint, "  duration = ", duration
      
      ; make sure the hjd is in barycentric MJD (HJD - 2400000.5d)
      if rawhjd0 lt 2400000 then begin
	hjd0 = rawhjd0
      endif else begin
	hjd0 = rawhjd0 - 2400000.5d
	mprint, "(converted hjd0 from ", rawhjd0, " to ", hjd0, " by subtracting 2400000.5)" 
      endelse
      
      candidate = {period:period, hjd0:hjd0, duration:duration, depth:0.0, depth_uncertainty:1000.0, n_boxes:0, n_points:0, rescaling:1.0, ratio:0.0, inflation_for_bad_duration:1.0}
      if n_elements(candidates) eq 0 then begin
	candidates = [candidate] 
      endif else begin
	candidates = [candidates, candidate]
      endelse
    endfor
  endfor
  print, candidates
  
  restore, star_dir() + typical_candidate_filename
  save,  filename=star_dir() + 'backup_candidates.idl', best_candidates
  
  best_candidates = [best_candidates, candidates]
  save, filename=star_dir() + typical_candidate_filename, best_candidates
  return, candidates
END