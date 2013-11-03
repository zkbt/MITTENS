

PRO fit_cumulative_planets
	common params, coef
	coef = {k_R:1.0, alpha:-1.92, k_P:0.064, beta:0.27, P_0:7.0, gamma:2.6}

	less_than_radius  = [0.7, 1.0, 1.4, 2.0, 2.8, 4.0, 5.7, 8.0, 11.3, 16.0, 22.6]
	less_than_period = [10, 50]
	cumulative = [[0.032, 0.131, .118, .095, 0.028, 0.006, 0.004, 0.0, 0.003, 0.004, 0.003], [0.032, 0.194, 0.245, 0.211, 0.187, 0.006, 0.004, 0.0, 0.003, 0.004, 0.003]]
	cumulative_upper = [[0.03, 0.0414, 0.0286, 0.0179, 0.0154, 0.0088, 0.0067, 0.005, 0.0048, 0.0059, 0.0044],[0.0300, 0.054, 0.0480, 0.0462, 0.0473, 0.0088, 0.0067, 0.005, 0.0048, 0.0059, 0.0044]]
	
	n_radii = n_elements(less_than_radius)
	n_periods = n_elements(less_than_period)
	model_prediction = fltarr(n_radii, n_periods)
;	high_res_grid = 
	dperiod = 0.1
	dradius = 0.1
	for i=0, n_radii-1 do begin
		min_radius = 0.5
		max_radius = less_than_radius[i]
		radius = findgen((max_radius - min_radius)/dradius + 1)*dradius + min_radius
		radius_integral = int_tabulated(radius, coef.k_r*radius^coef.alpha)
		print, 'R:',min_radius, max_radius, radius_integral
		for j=0, n_periods-1 do begin
			min_period = 0.5
			max_period = less_than_period[j]
			period = findgen((max_period - min_period)/dperiod + 1)*dperiod + min_period
			period_integral = int_tabulated(period, coef.k_r*period^coef.alpha)
			print, 'P:', min_period, max_period, period_integral
model_prediction[i,j] = radius_integral*period_integral
		endfor
		print
	endfor
	contour, model_prediction, less_than_radius, less_than_period, nlevels=100, /fill
stop	
END

FUNCTION fit_dfdlogperiod, period
	common params
	return, coef.k_P*period^coef.beta*(1-exp(-(period/coef.P_0)^coef.gamma))
END

FUNCTION fit_dfdlogradius,  radius
	common params
	return, coef.k_R*radius^coef.alpha;*(radius lt 2.0)
END