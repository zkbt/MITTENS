FUNCTION g, x
return, (0.5 + 0.5*erf(double(x)/sqrt(2)))
END

PRO estimate_neit, p_fa=p_fa, remake=remake
;+
; NAME:
;	ESTIMATE_NEIT
; PURPOSE:
;	estimate the number of effective independent tests we're making when searching a light curve (assuming that results of enough bootstrap simulations exist to make it worthwhile)
; CALLING SEQUENCE:
;	estimate_neit, p_fa=p_fa, remake=remake
; INPUTS:
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	p_fa = false alarm probability near which N_eit should be estimated
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	save the estimate of n_eit to the star directory
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
	
	; look for bootstrap simulation results	
	f = file_search(star_dir + 'eit/*/fepf_result.idl')

	; skip if there aren't enough
	if n_elements(f) le 50 then begin
		mprint, skipping_string, 'not enough bootstrap samples to calculate # of effective independent tests!'
		return
	endif

	; skip if up-to-date
	if is_uptodate(star_dir + 'eit/n_eit.idl', star_dir + 'eit/') and not keyword_set(remake) then begin
		mprint, skipping_string, 'number of effective independent tests is up to date!'
		return
	endif

	; make an estimate if there are enough
	mprint, doing_string, 'calculating # of effective independent tests'
	chi = fltarr(n_elements(f))
	for i=0, n_elements(f)-1 do begin
		restore, f[i], /RELAXED_STRUCTURE_ASSIGNMENT
		chi[i] = candidate.chi
	endfor
	ccdf = ccdf(sqrt(chi))
	
	; match the CCDF near the desired false alarm probability with a Gaussian distribution (see Jenkins 2002)
	if not keyword_set(p_fa) then p_fa = 0.01 > 5.0/n_elements(f)
	x_fa = interpol(ccdf.x,ccdf.y/p_fa - 1.0, 0.0)
	n_eit = alog(1.0 - p_fa)/alog(g(x_fa))
	print, star_dir, ' | N_eit = ', n_eit
	
	if keyword_set(display) then begin
		xplot, 15, title=star_dir + ' | effective independent tests'
		plot, ccdf.x, ccdf.y, /ylog
		oplot, ccdf.x, 1.0 -g(ccdf.x)^n_eit[0], linestyle=1
	endif

	; save the result (to be loaded up over an ensemble of stars and fit, elsewhere)
	save, filename=star_dir + 'eit/n_eit.idl', n_eit
	
END
