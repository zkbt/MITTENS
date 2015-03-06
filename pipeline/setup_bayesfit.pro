FUNCTION setup_bayesfit, lc, templates, display=display, use_sin=use_sin, fix_nights=fix_nights, use_constant=use_constant
;+
; NAME:
;	BAYESFIT
; PURPOSE:
;	Used by clean_lightcurve.pro to fit for and remove effects of external parameters and stellar variability on MEarth light curves.
; CALLING SEQUENCE:
; 
;	 superfit, lc, templates, star_dir, display=display, priors=prior
; 
; INPUTS:
;	
;	lc			=	light curve structure
;	templates	=	template structure (must have same number of data points per curve as lc)
; 
; KEYWORD PARAMETERS:
; 
;	
; 
; OUTPUTS:
; 
;	
; 
; RESTRICTIONS:
; 
;	
; 
; EXAMPLE:
; 
;	
; 
; MODIFICATION HISTORY:
;
; 	Written by ZKB.
;
;-

	@filter_parameters
	i_consider = where(lc.okay)
	N = n_elements(i_consider)
	rescaling = mean(lc.fluxerr)

	; set up structure to store information about the fit
	fit = replicate({name:'', solved:1B, zero:0.0, rescaling:1.0, is_variability:0B, is_needed:0B, weight:0.0, coef:0.0, uncertainty:0.0}, n_tags(templates)+1)
	t = tag_names(templates)

	; set names of the fitting parameters
	for i=0, n_tags(templates)-1 do fit[i].name = t[i]
	fit[n_tags(templates)].name = 'UNCERTAINTY_RESCALING'

	; specify which fit parameters are caused by variability of the star
	fit.is_variability = strmatch(fit.name, 'NIGHT*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'SIN*') eq 1

	; set up each template for fitting
	for i=0, n_tags(templates)-1 do begin
		if n_elements(templates.(i)) ne n_elements(lc) then begin
			mprint, ':-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-('
			mprint, "     in setup_bayesfit.pro, light curve and template sizes don't match!"
			mprint, "             GIVING UP!"
			mprint, ':-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-(:-('
			return, lc
		end
		; clean + normalize the templates	

		if fit[i].is_variability eq 0 and strmatch(fit[i].name, '*MERID*') eq 0 and strmatch(fit[i].name, '*VERSION*') eq 0 and strmatch(fit[i].name, '*CONSTANT') eq 0 and (strmatch(fit[i].name, '*XLC*') eq 0) and  (strmatch(fit[i].name, '*YLC*') eq 0) then begin
			fit[i].zero = mean(templates.(i), /nan)
			fit[i].rescaling = stddev(templates.(i), /nan)
			i_bad = where(abs((templates.(i) - fit[i].zero)/fit[i].rescaling) gt n_sigma_consider or finite(/nan, templates.(i)), complement=i_good, n_bad)
			if n_bad gt 0 and (N-n_bad) gt 2 then templates.(i)[i_bad] = interpol(templates.(i)[i_good], i_good, i_bad)
			fit[i].zero = mean(templates.(i), /nan)
			fit[i].rescaling = stddev(templates.(i), /nan)
			templates.(i) = (templates.(i) - fit[i].zero)/fit[i].rescaling
		endif

		if stddev(templates.(i)) eq 0 then fit[i].solved = 0
	endfor

	if keyword_set(use_constant) then begin
		i = where(strmatch(fit.name, '*CONSTANT*') , n)
		if n gt 0 then fit[i].solved = 1
	endif
	; MAKE UP YOUR MIND ABOUT SINS AND COSES!
	fit.solved = fit.solved and (strmatch(fit.name, 'UNCERTAINTY_RESCALING') eq 0) and  (strmatch(fit.name, '*XLC*') eq 0) and  (strmatch(fit.name, '*YLC*') eq 0)  and fit.rescaling ne 0
	if ~ keyword_set(use_sin) then fit.solved = fit.solved AND strmatch(fit.name, 'COS*') eq 0 and strmatch(fit.name, 'SIN*') eq 0
	if keyword_set(fix_nights) then fit.solved = fit.solved AND (strmatch(fit.name, 'NIGHT*') eq 0) 
;	fit.solved = fit.solved and (strmatch(fit.name, 'UNCERTAINTY_RESCALING') eq 0) and fit.rescaling ne 0 and strmatch(fit.name, 'NIGHT*') eq 0; and strmatch(fit.name, 'SIN*') eq 0)
 	return, fit
END
;