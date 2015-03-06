
FUNCTION superfit, lc, templates, star_dir, priors=prior;display=display, 
;+
; NAME:
;    
;	SUPERFIT
; 
; PURPOSE:
; 
;	Used by filter_lightcurve.pro to remove scaled verisons of 
; 
; CALLING SEQUENCE:
; 
;	 decorrelate, lc, templates, star_dir, i_consider=i_consider
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
	common mearth_tools

	@filter_parameters
	i_consider = where(lc.okay)
	N = n_elements(i_consider)
	rescaling = mean(lc.fluxerr)

	; set up structure to store information about the fit
	fit = replicate({name:'', solved:0B, is_variability:0B, is_needed:0B, weight:0.0, coef:0.0, uncertainty:0.0}, n_tags(templates))
	t = tag_names(templates)

	for i=0, n_tags(templates)-1 do begin
		if n_elements(templates.(i)) ne n_elements(lc) then begin
			printl, ':-('
			print, "     in superfit.pro, light curve and template sizes don't match!"
			print, "             GIVING UP!"
			printl, ':-('
			return, lc
		end
		; clean + normalize the templates		
		if total(finite(templates.(i))) gt 3 then begin
			if strmatch(t[i], 'MERID') eq 0 and strmatch(t[i], 'NIGHT*') eq 0 and strmatch(t[i], 'SIN*') eq 0 and strmatch(t[i], 'COS*') eq 0 then begin
				templates.(i) -= mean(templates.(i), /nan)
				if stddev(templates.(i), /nan) gt 0 then templates.(i) = templates.(i)/stddev(templates.(i), /nan)
				i_bad = where(abs(templates.(i)) ge n_sigma_consider or finite(/nan, templates.(i)), complement=i_good, n_bad)
				if n_bad gt 0 and (N-n_bad) gt 2 then templates.(i)[i_bad] = interpol(templates.(i)[i_good], i_good, i_bad)
				templates.(i) = (templates.(i) - mean(templates.(i)))
				if stddev(templates.(i)) gt 0 then templates.(i) = templates.(i)/stddev(templates.(i))*rescaling
			endif

		endif
		fit[i].name = t[i]
	endfor
  fit.is_variability = strmatch(fit.name, 'NIGHT*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'SIN*') eq 1
 
  ; handle priors from previous fit
  if keyword_set(priors) then begin
     
  endif else begin
     fit.solved = strmatch(fit.name, 'EXPTIME') eq 0
  endelse
	i_include = where(fit.solved, M)

	; give up if there are no good templates
	if M eq 0 then begin
		print, '          no significant template correlations were found!'
		return, lc
	endif 

  ; do svd fit
	A = dblarr(N,M)
	err = lc[i_consider].fluxerr#ones(M)
	for i=0, M-1 do A[*,i] = templates.(i_include[i])[i_consider]
	A /= err
	b = lc[i_consider].flux/lc[i_consider].fluxerr	
	svdc, A, W, U, V, /double, /column
	coef = dblarr(M)
	variances = dblarr(M)
	singular_limit = 1e-5
	for i=0, M-1 do begin
		if w[i] gt singular_limit then begin
			coef += total(u[*,i]*b)/w[i]*v[*,i]
			variances += (v[*,i]/w[i])^2
			fit[i_include[i]].is_needed = 1
		endif else begin
		  fit[i_include[i]].is_needed = 0
		end
	endfor
	fit[i_include].weight = w
	
	fit[i_include].coef = coef
	fit[i_include].uncertainty = sqrt(variances)


	decorrelation = dblarr(n_elements(lc))
	variability = dblarr(n_elements(lc))
	variability_uncertainty = dblarr(n_elements(lc))
	for i=0, M-1 do begin
		;templates.(i_include[i]) *= coef[i]
		if fit[i_include[i]].is_variability then begin
		    variability += coef[i]*templates.(i_include[i])
		    is_nightly = strmatch(fit[i_include[i]].name, 'NIGHT*')
        if is_nightly then begin
          i_thisnight = where(templates.(i_include[i]) eq 1.0)
          variability_uncertainty[i_thisnight] = fit[i_include[i]].uncertainty
          if total(lc[i_thisnight].okay) eq 0 then variability_uncertainty[i_thisnight] = stddev(lc.flux) 
        endif
		endif else begin
		  decorrelation += coef[i]*templates.(i_include[i])
		endelse
	endfor

	if keyword_set(display) then begin
			tags = i_include
			amplitude = fltarr(M)
			scaled_templates = templates
			for i=0, M-1 do begin
				scaled_templates.(i) = templates.(i_include[i])*coef[i]
				amplitude[i] = stddev(scaled_templates.(i_include[i]))
			endfor
			tags = tags[reverse(sort(amplitude))]
			nightly_tags = tags[where(strmatch(fit[tags].name, 'NIGHT*') eq 1)]
			systematic_tags = tags[where(strmatch(fit[tags].name, 'NIGHT*') eq 0)]
			nightly_tags = nightly_tags[sort(nightly_tags)]
		;	nightly_tags = nightly_tags[0:n_elements(systematic_tags)-1]
	; 		device, filename=star_dir + 'decorrelation.eps', /inches, /encapsulated, xsize=7.5, ysize=n_elements(tags)+3
			scale = 2*1.48*mad(lc.flux); < max(abs(lc.flux)) < 0.1
	
			!p.thick=1
			!p.charsize=1.5
			!p.charthick=2
			!p.symsize=0.7
			!y.range = [scale, -scale]
			temp_structure = create_struct('RAW', lc.flux, 'DECORRELATED', lc.flux - decorrelation,'RESIDUALS',  lc.flux - decorrelation - variability, scaled_templates)
; 			set_plot, 'ps'
; 			!p.noclip=1
; 			device, filename='systematics_fit.eps', /encap, /inches, xsize=12, ysize=16
; 			plot_struct, temp_structure, tags=[0,systematic_tags+3,1], ystyle=7, xstyle=5
; 			device, /close	
; 			device, filename='nightly_fit.eps', /encap, /inches, xsize=12, ysize=16
; 			plot_struct, temp_structure, tags=[1,nightly_tags+3,2], ystyle=7, xstyle=5
; 			device, /close
; 			!p.noclip=0
; 			epstopdf, 'systematics_fit.eps'
; 			epstopdf, 'nightly_fit.eps'
		endif
 		 result = create_struct('lc', lc, 'decorrelation', decorrelation, 'variability', variability, 'variability_uncertainty', variability_uncertainty, 'cleaned', lc.flux - decorrelation - variability, 'fit', fit)
	return, result
END


