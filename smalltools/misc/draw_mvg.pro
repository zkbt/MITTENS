FUNCTION draw_mvg, central_values, covariance_matrix, n_draws

	; pull out only the non-singular rows + columns of the covariance_matrixiance matrix
	n_parameters = n_elements(covariance_matrix[*,0])
	i_varying = where(covariance_matrix[indgen(n_parameters), indgen(n_parameters)] ne 0, n_varying_parameters)
	temp = covariance_matrix[i_varying,*]
	varying_covariance_matrix = temp[*,i_varying]
	decomposition = cholesky(varying_covariance_matrix)

	; generate fake array of parameters (even
	mvg = fltarr(n_parameters, n_draws)
	for i=0l, n_draws-1 do begin
		mvg[*,i] = central_values
		mvg[i_varying,i] += randomn(seed,n_varying_parameters)#decomposition
	endfor
	

	return, mvg
END