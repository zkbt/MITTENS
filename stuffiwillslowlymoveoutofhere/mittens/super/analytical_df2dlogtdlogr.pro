FUNCTION analytical_df2dlogtdlogr, temperature_grid, radius_grid, coef=coef
	r0 = coef.b/(1.0 + (coef.pfunny/temperature_grid)^coef.beta) 
	model = (temperature_grid/coef.a)^coef.alpha/(1.0 + exp((radius_grid  - r0)/coef.c));*radius_grid^(-coef.ra);*(1.0- exp(-temperature_grid/coef.p0));
	return, model;+ coef.k2*radius_grid^coef.alpha2)
;	original howard et al.
;	return, coef.k*(radius_grid^coef.alpha*temperature_grid^coef.beta*(1-exp(-(temperature_grid/coef.P_0)^coef.gamma)));+ coef.k2*radius_grid^coef.alpha2)
END