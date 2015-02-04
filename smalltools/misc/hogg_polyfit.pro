FUNCTION hp_deviates, coef, order=order, x=x, y=y, uncertainty_y=uncertainty_y, evaluate=evaluate
	n = n_elements(x)
	model = dblarr(n)
	for i=0, order do model += coef[i]*x^i
	if keyword_set(evaluate) then return, model
	deviates = (y-model)/uncertainty_y
	return, deviates
END

FUNCTION hp_likelihood, order=order, x=x, y=y, uncertainty_y=uncertainty_y,  parameters=parameters
	
	outlier_mean = parameters.outlier_mean
	outlier_variance = parameters.outlier_variance
	outlier_probability = parameters.outlier_probability

	if tag_exist(parameters, 'UNCERTAINTY_RESCALING') then uncertainty_rescaling = parameters.uncertainty_rescaling else uncertainty_rescaling = 1.0
	if tag_exist(parameters, 'INTRINSIC_SCATTER') then intrinsic_scatter = parameters.intrinsic_scatter else intrinsic_scatter = 0.0
	
	coef = fltarr(order+1)
	for i=0, order do coef[i] = parameters.(i)
	model = hp_deviates(coef, order=order, x=x, /evaluate)
	rescaled_sigma = (uncertainty_rescaling*uncertainty_y)
	
	first_term = (1.0-outlier_probability)/sqrt(2*!pi*(rescaled_sigma^2 + intrinsic_scatter^2))*exp(-(y-model)^2/2/(rescaled_sigma^2+ intrinsic_scatter^2))
	second_term =  outlier_probability/sqrt(2*!pi*(outlier_variance + rescaled_sigma^2))*exp(-(y-outlier_mean)^2/2/(outlier_variance + rescaled_sigma^2))
	per_point_likelihood = first_term + second_term

	log_likelihood = total(alog(per_point_likelihood))
	return, log_likelihood
END

FUNCTION hp_prior, parameters=parameters
	
	; flat prior in coefficients
	log_prior =  0.0

	infinity = 1000000.0

	; what priors on the others?
	if parameters.outlier_probability lt 0 or parameters.outlier_probability gt 1 then log_prior -= infinity

	; what priors on the others?
	if parameters.outlier_variance lt 0 then log_prior -= infinity

	if tag_exist(parameters, 'INTRINSIC_SCATTER') then if parameters.intrinsic_scatter lt 0 then log_prior -= infinity

	return, log_prior
END

FUNCTION hp_accept, proposed_log_posterior, current_log_posterior, seed

	;if proposed has higher loglikelihood, then keep it
	if (proposed_log_posterior ge current_log_posterior) then begin
		return, 1B
	endif else begin	
		; if not, then keep with some probability 
		alpha = exp(proposed_log_posterior - current_log_posterior);exp(0.5*(x.chi_sq - x_prime.chi_sq))
		if (randomu(seed) lt alpha) then begin
			; new
			return, 1B 
		endif else begin
			return, 0B
		endelse
	endelse
END

FUNCTION hp_perturb, x, seed, cholesky
	
	n = n_tags(x)
	x_prime = x
	kicks = randomn(seed, n)#cholesky
	for i=0, n-1 do x_prime.(i) = x.(i) + kicks[i]
	return, x_prime
END



FUNCTION hogg_polyfit, input_x, input_y, input_uncertainty_y, order=order, rescale=rescale, intrinsic_scatter=intrinsic_scatter, plot=plot, xtitle=xtitle, ytitle=ytitle, n_chain=n_chain
	
	if n_elements(input_uncertainty_y) eq 1 then uncertainty_y = ones(n_elements(input_x))*input_uncertainty_y else uncertainty_y = input_uncertainty_y
	i_ok = where(finite(input_x) and finite(input_y) and finite(input_uncertainty_y), n_finite)
	if n_finite gt 0 then begin
		x = input_x[i_ok]
		y = input_y[i_ok]
		uncertainty_y = uncertainty_y[i_ok]
	endif else begin
		print, 'NO FINITE ELEMENTS!'
	endelse	
	


	; some definitions
	if ~keyword_set(order) then order = 1
	n = n_elements(x)
	if strmatch(xtitle, '*TYPE*') ne 0 then off = (randomu(seed, n) - 0.5)*0.2 else off = fltarr(n)

	t_lastplot = 0

	; establish an initial guess for the (regular) parameters
	functargs = {order:order, x:x, y:y, uncertainty_y:uncertainty_y}

	initial_guess = mpfit('HP_DEVIATES', float(ones(order+1)), functargs=functargs, covar=covar, status=status, errmsg=errmsg, dof=dof, bestnorm=bestnorm, nfev=nfev, nfree=nfree, niter=niter, nocovar=0, perror=perror, parinfo=parinfo)
	cleanplot
	xplot
	loadct, 39
	@psym_circle
	ploterror, x+off, y, uncertainty_y, psym=8, xtitle=xtitle, ytitle=ytitle
	oplot, x+off, hp_deviates(initial_guess, order=order, x=x, /evaluate), color=250, psym=8

	; setup parameter arrays
	if ~keyword_set(n_chain) then n_chain = 1000000L
	initial_hyper_parameters = {outlier_probability:0.1, outlier_variance:max(y) - min(y), outlier_mean:mean(y)}
	if keyword_set(rescale) then initial_hyper_parameters = create_struct(initial_hyper_parameters, 'UNCERTAINTY_RESCALING', 1.0)
	if keyword_set(intrinsic_scatter) then  initial_hyper_parameters = create_struct(initial_hyper_parameters, 'INTRINSIC_SCATTER', 0.0)

	initial_regular_parameters = create_struct('POLY0', initial_guess[0])
	for i=1, order do initial_regular_parameters = create_struct(initial_regular_parameters, 'POLY'+rw(i), initial_guess[i])
	parameters = replicate(create_struct(initial_regular_parameters, initial_hyper_parameters), n_chain)
	proposed_probability = {log_likelihood:0.0, log_prior:0.0, log_posterior:0.0}
	probabilities = replicate(proposed_probability, n_chain)
	probabilities[0].log_prior = hp_prior(parameters=parameters[0]) 
	probabilities[0].log_likelihood = hp_likelihood(order=order, x=x, y=y, uncertainty_y=uncertainty_y,  parameters=parameters[0]) 
	probabilities[0].log_posterior = probabilities[0].log_likelihood + probabilities[0].log_prior

	m = n_tags(parameters[0])
	covariance_matrix = fltarr(m, m)
	covariance_matrix[0:order, 0:order] = covar*10
	i = where(strmatch(tag_names(parameters[0]), 'OUTLIER_PROBABILITY'), n_match)
	if n_match gt 0 then covariance_matrix[i,i] = 0.01
	i = where(strmatch(tag_names(parameters[0]), 'OUTLIER_VARIANCE'), n_match)
	if n_match gt 0 then covariance_matrix[i,i] = stddev(y)
	i = where(strmatch(tag_names(parameters[0]), 'OUTLIER_MEAN'), n_match)
	if n_match gt 0 then covariance_matrix[i,i] = stddev(y)
	i = where(strmatch(tag_names(parameters[0]), 'UNCERTAINTY_RESCALING'), n_match)
	if n_match gt 0 then covariance_matrix[i,i] = 0.1
	i = where(strmatch(tag_names(parameters[0]), 'INTRINSIC_SCATTER'), n_match)
	if n_match gt 0 then covariance_matrix[i,i] = stddev(y-hp_deviates(initial_guess, order=order, x=x, /evaluate))*0.1

	
	xplot, title='Covariances', xsize=800, ysize=800, 1
	xplot, title='Chains', xsize=500, ysize=1000, 2
	xplot, title='Data + Model', xsize=2000, ysize=500, 3

	decomposition = cholesky(covariance_matrix)
	for i=1L, n_chain-1 do begin
		proposed_parameters = hp_perturb(parameters[i-1], seed, decomposition)
		proposed_probability.log_prior = hp_prior(parameters=proposed_parameters) 
		if proposed_probability.log_prior gt -99999.9 then proposed_probability.log_likelihood = hp_likelihood(order=order, x=x, y=y, uncertainty_y=uncertainty_y,  parameters=proposed_parameters) 
		proposed_probability.log_posterior = proposed_probability.log_likelihood + proposed_probability.log_prior
;		print_struct, [proposed_probability, probabilities[i-1]]
		if hp_accept(proposed_probability.log_posterior, probabilities[i-1].log_posterior, seed) then begin
			parameters[i] = proposed_parameters 
			probabilities[i] = proposed_probability
;			print, "ACCEPTED!"
		endif else begin
			parameters[i] = parameters[i-1]	
			probabilities[i] = probabilities[i-1]
	;		print, "REJECTED!"

		endelse
; 		plot, x, y, psym=8
; 		oploterr, x, y, uncertainty_y
; 		coef = fltarr(order+1)
; 		for j=0, order do coef[j] = proposed_parameters.(j)
; 		oplot, x, hp_deviates(coef, order=order, x=x, /evaluate), color=250, psym=8

		if i mod 10000 eq 0 and keyword_set(plot) then begin
			counter, i, n_chain, /timeleft, 'completed: ', starttime=starttime
			if systime(/sec) - t_lastplot gt 60 then begin
				wset, 3
				plot, x, y, /nodata, xs=3, ys=3, xtitle=xtitle, ytitle=ytitle
				n_grid = 50
				x_axis = findgen(n_grid)/n_grid*(max(x) - min(x)) + min(x)
				for j=0, 10 do begin
					which = randomu(seed)*i
					model = fltarr(n_grid)
					for k=0, order do model += parameters[which].(k)*x_axis^k		
					oplot, x_axis, model, thick=1, color=150	
				endfor	
				oploterr, x+off, y, uncertainty_y, 8
				wset, 1
				plot_ndpdf, parameters[0:i], psym=3
				wset, 2
				!p.charsize=1.5
				!x.margin =[10,5]
				!y.margin=[5,5]
				erase
				plot_struct, parameters[0:i]
				t_lastplot = systime(/sec)
			endif
		endif
;		if question(/int, 'hey?') then stop
	endfor
	return, parameters[lindgen(n_chain/100)*100]
END