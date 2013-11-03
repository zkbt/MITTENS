FUNCTION load_candidates, combined=combined
;+
; NAME:
;	LOAD_CANDIDATES
; PURPOSE:
;	search through MEarth directories, return candidates
; CALLING SEQUENCE:
; 	c = load_candidates(combined=combined)
; INPUTS:
;
; KEYWORD PARAMETERS:
;	/combined = search combined light curves as well as individual years 
; OUTPUTS:
;	array of {candidate} structures 
; RESTRICTIONS:
; 
; EXAMPLE:
; 	c = load_candidates(combined=combined)
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-

	if keyword_set(combined) then  f = file_search('ls*/*/blind/best/candidate.idl') else  f = file_search('ls*/ye*/te*/blind/best/candidate.idl')

  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  n = n_elements(f)
  s = create_struct('LSPM', 0, 'STAR_DIR', '', {candidate} )
  cloud = replicate(s, n)
  for i=0, n-1 do begin
    restore, f[i]
    copy_struct, candidate, s
    cloud[i] = s
    cloud[i].lspm = ls[i]
    cloud[i].star_dir = stregex(f[i], /ext, 'ls[0-9]+/(ye[0-9]+/te[0-9]+|combined)') +'/'
  endfor  
  return, cloud[(sort(cloud.fap))]
END 