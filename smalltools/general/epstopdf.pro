PRO epstopdf, filename, pause=pause
;+
; NAME:
;	EPSTOPDF
; PURPOSE:
;	convert EPS to PDF, and display on screen
; CALLING SEQUENCE:
; 	epstopdf, filename, pause=pause
; INPUTS:
;	filename = name of an EPS file, with or without the .eps suffix
; KEYWORD PARAMETERS:
;	/pause = wait for user to close the displayed PDF before continuing
; OUTPUTS:
;	if run on UNIX, creates a .pdf file in the same location as the .eps
;	if run on Mac, just opens the .eps in Preview
; RESTRICTIONS:
; 	
; EXAMPLE:
; 	epstopdf, 'test.eps'
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-

  if strmatch(filename, '*.eps') ne 0 then name = strmid(filename, 0, strpos(filename, '.eps')) else name = filename
  if strmatch(!VERSION.OS_NAME, '*Mac*') then begin
    spawn, 'open ' + name + '.eps'
  endif else begin
  	spawn, 'umask 0007; epstopdf ' + name + '.eps'
  	str = 'acroread ' + name + '.pdf'
  	if not keyword_set(pause) then str += '&'
  	spawn, str
  endelse
END