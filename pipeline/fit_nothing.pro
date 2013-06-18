FUNCTION fit_nothing, lc, templates, fit, priors, nothing, variability_model=variability_model, systematics_model=systematics_model, uncertainty_overall_model=uncertainty_overall_model, uncertainty_variability_model=uncertainty_variability_model

	common mearth_tools
	@filter_parameters
	tonight = round(nothing.hjd-mearth_timezone())
	nights = round(lc.hjd-mearth_timezone())
	i_consider = where(lc.okay and nights eq tonight, N)
	i_tonight = where(nights eq tonight, N_tonight)
	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'SIN*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
	N_withpriors = N + M
	M_withnothing = M
	i_seasonwide_rescaling = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_seasonwidematch)
	if n_seasonwidematch eq 1 then seasonwide_rescaling = priors[i_seasonwide_rescaling].coef


	if n eq 0 then begin
		coef = priors[i_include].coef
	endif else begin
		;	for k=0, n_elements(nothing.duration)-1 do begin
		k=0
		this_nothing = {hjd0:nothing.hjd}
		; loop until rescaling converges
		rescaling = 1.0
		converged = 0
		while(~converged) do begin
			previous_rescaling = rescaling

	
			; set up model
			A = dblarr(N_withpriors, M_withnothing)
			for i=0, M-1 do A[0:N-1,i] = templates.(i_include[i])[i_consider]/lc[i_consider].fluxerr/rescaling
			for i=0, M-1 do A[N+i,i] = 1.0/priors[i_include[i]].uncertainty;templates.(i_include[i])[i_consider]
	
			; setup data + priors
			b = fltarr(N_withpriors)
			b[0:N-1] = lc[i_consider].flux/lc[i_consider].fluxerr/rescaling
			b[N:*] = priors[i_include].coef/priors[i_include].uncertainty
	
			svdc, A, W, U, V, /double, /column
			coef = dblarr(M_withnothing)		
	
			variances = dblarr(M_withnothing)
			if keyword_set(demo_plot) or n_elements(uncertainty_overall_model) gt 0 then covariances = dblarr(M,M)

			singular_limit = 1e-5
			for i=0, M_withnothing-1 do begin
				if w[i] gt singular_limit then begin
					coef += total(u[*,i]*b)/w[i]*v[*,i]
					variances += (v[*,i]/w[i])^2
					if keyword_set(demo_plot) or n_elements(uncertainty_overall_model) gt 0 then for k_demo=0, M-1 do covariances[*,k_demo] +=(v[*,i]*v[k_demo,i]/w[i]^2)

		;			fit[i_include[i]].is_needed = 1
				endif else begin
			;		fit[i_include[i]].is_needed = 0
				end
			endfor
			fit[i_include].weight = w[0:M-1]
			fit[i_include].coef = coef[0:M-1]
			fit[i_include].uncertainty = sqrt(variances[0:M-1])
			nothing.n = N

			if n_elements(variability_model) gt 0 and n_elements(systematics_model) gt 0 then begin
				i_systematics = where(fit[i_include].is_variability eq 0, M_systematics)
				i_variability = where(fit[i_include].is_variability, M_variability)
				variability_model[i_tonight] =0
				systematics_model[i_tonight] =0
				for i=0, M_variability-1 do variability_model[i_tonight] += coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
				for i=0, M_systematics-1 do systematics_model[i_tonight] += coef[i_systematics[i]]*templates.(i_include[i_systematics[i]])[i_tonight]

					if n_elements(uncertainty_variability_model) gt 0 and n_elements(uncertainty_overall_model) gt 0 then begin
						n_draws = 25
						ensemble_overall = fltarr(n_elements(i_tonight), n_draws)
						ensemble_variability = fltarr(n_elements(i_tonight), n_draws)
						for q=0, n_draws-1 do begin
							temporary_coef = draw_mvg(coef, covariances, 1)
							for i=0, M_variability-1 do ensemble_variability[*,q] += temporary_coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
							ensemble_variability[*,q] -= variability_model[i_tonight]
							for i=0, M_variability-1 do ensemble_overall[*,q] += temporary_coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
							for i=0, M_systematics-1 do ensemble_overall[*,q]  += temporary_coef[i_systematics[i]]*templates.(i_include[i_systematics[i]])[i_tonight]
							ensemble_overall[*,q] -= (variability_model[i_tonight] + systematics_model[i_tonight])
						endfor
						uncertainty_variability_model[i_tonight] = sqrt(total(ensemble_variability^2, 2)/n_draws)
						uncertainty_overall_model[i_tonight] = sqrt(total(ensemble_overall^2,2)/n_draws)
					endif
						
			endif
	
			model = fltarr(n) 
			for i=0, M-1 do model += coef[i]*templates.(i_include[i])[i_consider]
			residuals = lc[i_consider].flux - model
	
			chi_sq = total((residuals/lc.fluxerr)^2);+ total(deviates_from_prior^2)

				rescaling = sqrt((chi_sq + seasonwide_rescaling^2*n_effective_for_rescaling)/(n + n_effective_for_rescaling)) > 1; sqrt(chi_sq/n) > 1
			converged = abs((rescaling - previous_rescaling)/rescaling) lt 0.01
			fit[n_elements(fit)-1].coef = rescaling
			fit[n_elements(fit)-1].uncertainty = priors[n_elements(fit)-1].uncertainty;sqrt(chi_sq/n^2/2.0)
		endwhile
	endelse

	return, nothing
END