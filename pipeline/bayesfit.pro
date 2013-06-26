FUNCTION bayesfit, lc, templates, fit, priors, outputs=outputs, systematics_model=systematics_model, variability_model=variability_model, residuals=residuals


   ; handle priors from previous fit
	i_consider = where(lc.okay, N)
	i_include = where(fit.solved, M)

	N_withpriors = N + M
	M_withgrazer = M + 1

	rescaling = 1
	converged = 0
	count = 0
	; loop until rescaling converges
	while(~converged) do begin
		count +=1
		previous_rescaling = rescaling

		; set up model
		A = dblarr(N_withpriors, M_withgrazer)
		for i=0, M-1 do A[0:N-1,i] = templates.(i_include[i])[i_consider]/lc[i_consider].fluxerr/rescaling
		for i=0, M-1 do A[N+i,i] = 1.0/priors[i_include[i]].uncertainty;templates.(i_include[i])[i_consider]
		
		; setup data + priors
		b = fltarr(N_withpriors)
		b[0:N-1] = lc[i_consider].flux/lc[i_consider].fluxerr/rescaling
		b[N:*] = priors[i_include].coef/priors[i_include].uncertainty
		
		; svd fit, ignoring singular parameters (variable names are the same as in N. Recipes)	
		svdc, A, W, U, V, /double, /column
		coef = dblarr(M)
		variances = dblarr(M)
		covariances = dblarr(M,M)
		singular_limit = 1e-5
		for i=0, M-1 do begin
			if w[i] gt singular_limit then begin
				coef += total(u[*,i]*b)/w[i]*v[*,i]
				variances += (v[*,i]/w[i])^2
				for k=0, M-1 do covariances[*,k] +=(v[*,i]*v[k,i]/w[i]^2)
				fit[i_include[i]].is_needed = 1
			endif else begin
			fit[i_include[i]].is_needed = 0
			end
		endfor
	
		fit[i_include].weight = w[0:M-1]
		fit[i_include].coef = coef[0:M-1]
		fit[i_include].uncertainty = sqrt(variances[0:M-1])
	
		systematics_model = fltarr(n_elements(lc))
		variability_model = fltarr(n_elements(lc))
		i_systematics = where(fit[i_include].is_variability eq 0, M_systematics)
		i_variability = where(fit[i_include].is_variability, M_variability)
		for i=0, M_variability-1 do variability_model += coef[i_variability[i]]*templates.(i_include[i_variability[i]])
		for i=0, M_systematics-1 do systematics_model += coef[i_systematics[i]]*templates.(i_include[i_systematics[i]])
		model = variability_model + systematics_model
	
		residuals = lc.flux - model
		chi_sq = total((residuals[i_consider]/lc[i_consider].fluxerr)^2)
		fit[n_elements(fit)-1].coef = rescaling
		fit[n_elements(fit)-1].uncertainty = sqrt(chi_sq/n^2/2.0)
		rescaling = sqrt(chi_sq/n) > 1
		
;		print, string(format='(F5.2)', previous_rescaling),  ' --> ',  string(format='(F5.2)',rescaling)
		converged = abs((rescaling - previous_rescaling)/rescaling) lt 0.01 or count gt 20
;		fit[where(fit.solved)].uncertainty*=fit[n_elements(fit)-1].coef	; make sure this is legit!
	endwhile
	return,fit
END