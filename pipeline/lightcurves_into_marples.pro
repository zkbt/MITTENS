PRO lightcurves_into_marples, remake=remake, start=start
;+
; NAME:
;	lightcurves_into_marples
; PURPOSE:
;	loop over the population, converting lightcurves in marples
; CALLING SEQUENCE:
; lightcurves_into_marples, remake=remake, start=start
; INPUTS:
;	[remake] = should we remarplify stars that have already been marplified?
; [start] = a fraction from 0.0 to 1.0, saying where among the (RA-sorted) list of stars to begin processing (useful for parallel processing) 
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	messes with the file structures
; RESTRICTIONS:
; EXAMPLE:
;	lightcurves_into_marples, 
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime after 2008.
;-
	
	common mearth_tools

	; make text displayed within this procedure is labeled
	procedure_prefix = '[lightcurves_into_marples]'

	mprint, /line
	mprint, tab_string, 'lightcurves_into_marples.pro is taking the lightcurves located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating MarPLES (= transit depth probability distributions) from them'
	mprint, /line

	display, /off
	verbose, /on
	interactive, /off

	f = file_search('mo*/', /mark)
	if n_elements(start) eq 0 then start = 0
	for i=start*n_elements(f), n_elements(f)-1 do begin
		mo = name2mo(f[i])
		marplify, mo, remake=remake
	endfor
END
