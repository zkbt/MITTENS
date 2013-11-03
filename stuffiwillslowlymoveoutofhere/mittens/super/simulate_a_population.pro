FUNCTION dfdlogperiod, period, coef=coef
	return, coef.k_P*period^coef.beta*(1-exp(-(period/coef.P_0)^coef.gamma))
END

FUNCTION dfdlogradius,  radius, coef=coef
	return, coef.k_R*radius^coef.alpha;*(radius lt 2.0)
END



FUNCTION df2_deviates, params, inputs=inputs
	coef = array_to_struct(params, inputs.x_initial)
	period = 10^inputs.mid_logperiod_grid
	radius = 10^inputs.mid_logradius_grid
	model = inputs.distribution*0.0
	res = 100
	for i=0, n_elements(inputs.upper_logperiod)-1 do begin
		lower_period = 10^inputs.lower_logperiod[i]
		upper_period = 10^inputs.upper_logperiod[i]
		for j=0, n_elements(inputs.upper_logradius)-1 do begin
			lower_radius = 10^inputs.lower_logradius[j]
			upper_radius = 10^inputs.upper_logradius[j]
			dperiod = (upper_period - lower_period)/res
			dradius = (upper_radius - lower_radius)/res
			fine_period = findgen(res+1)*dperiod + lower_period
			fine_radius = findgen(res+1)*dradius + lower_radius
			fine_period_grid = fine_period#ones(n_elements(fine_radius))
			fine_radius_grid = ones(n_elements(fine_period))#fine_radius
			fine_dlogperiod_grid = dperiod/fine_period_grid*alog10(exp(1))
			fine_dlogradius_grid = dradius/fine_radius_grid*alog10(exp(1))
			fine_model = analytical_df2dlogpdlogr(fine_period_grid, fine_radius_grid, coef=coef)*fine_dlogperiod_grid*fine_dlogradius_grid
			model[i,j] = total(fine_model)
		endfor
	endfor
;	plot, model, coef.k*radius^coef.alpha*period^coef.beta*(1-exp(-(period/coef.P_0)^coef.gamma))
;	model = 
	data = inputs.distribution
	errors = inputs.errors
	i_ok = where(inputs.distribution gt 0 and 10^inputs.mid_logradius_grid lt 6 and 10^inputs.mid_logperiod_grid lt 29)

	;plot=1
		if keyword_set(plot) then begin

	!p.multi = [0,3,2]
	top = max( inputs.distribution)


 	contour, inputs.distribution, 10^(inputs.mid_logperiod), 10^(inputs.mid_logradius), /fill,  levels=findgen(200)/200*top, xs=3, xr=[0.5,50], yr=[0.8,10]
 	contour, model, 10^(inputs.mid_logperiod), 10^(inputs.mid_logradius), /fill,  levels=findgen(200)/200*top, xs=3, xr=[0.5,50], yr=[0.8,10]
;	
	fine_period = findgen(101)/100*max(period)
	fine_radius = findgen(101)/100*(max(radius) - min(radius)) + min(radius)
	fine_period_grid = fine_period#ones(n_elements(fine_radius))
	fine_radius_grid = ones(n_elements(fine_period))#fine_radius
	fine_model = analytical_df2dlogpdlogr(fine_period_grid, fine_radius_grid, coef=coef)*fine_dlogperiod_grid*fine_dlogradius_grid
 	contour, fine_model, fine_period, fine_radius, /fill,  levels=findgen(200)/200*top, xs=3, xr=[0.5,50], yr=[0.8,10]

	plot, radius[i_ok], (data[i_ok]-model[i_ok])/errors[i_ok], psym=1
	plot, period[i_ok], (data[i_ok]-model[i_ok])/errors[i_ok], psym=1
endif

	deviates = (data - model)/errors
	if total(finite(deviates[i_ok])) eq 0 then stop
;	if question(/, 'asgdsa') then stop
	return, deviates[i_ok]
END


FUNCTION simulate_a_population, sss, howard=howard, coolkois=coolkois, francois=francois, gj1214b=gj1214b, bumpy=bumpy, nofit=nofit, plot=plot
	common fitting_vars, inputs
	@planet_constants
	
	if keyword_set(gj1214b) then begin
		i_period = value_locate(sss.period_axis, 1.6)
		i_temperature = value_locate(sss.temperature_axis, 560)
		i_radius = value_locate(sss.radius_axis, 2.65)
		pop_period = sss.period_sensitivity*0.0d
		pop_temperature = sss.temperature_sensitivity*0.0d
		pop_period[i_period, i_radius] = 1.0/sss.dlogperiod_grid[i_period, i_radius]/sss.dlogradius_grid[i_period, i_radius]
		pop_temperature[i_temperature, i_radius] = 1.0/sss.dlogtemperature_grid[i_temperature, i_radius]/sss.dlogradius_grid[i_temperature, i_radius]
	endif
	;sss = super sampled sensitivity
	if keyword_set(howard) then begin
		coef = {k_R:1.0, alpha:-1.92, k_P:0.064, beta:0.27, P_0:7.0, gamma:2.6}
		coef.k_R = 1.0/((4^coef.alpha - 2^coef.alpha)/coef.alpha)/alog10(exp(1))
;		coef.k_R = 1.0/((max(sss.radius_grid)^coef.alpha - min(sss.radius_grid)^coef.alpha)/coef.alpha)/alog10(exp(1))

		pop_period = dfdlogperiod(sss.period_grid, coef=coef)*dfdlogradius(sss.radius_grid, coef=coef)
		earth_relative_flux = (sss.temperature_grid/280.0)^4.0
		temp_period_grid = 365.0*(earth_relative_flux)^(-0.75)
		pop_temperature = 3.0*dfdlogperiod(temp_period_grid, coef=coef)*dfdlogradius(sss.radius_grid, coef=coef)
		
		return, {period:pop_period, temperature:pop_temperature}
	endif

	if keyword_set(coolkois) then begin;and keyword_set(bumpy)
;;		readcol, '4zach/cool_stars.txt', KID, teff, radius, mass, logg, feh, luminosity, distance, kic_teff, kic_radius, kic_logg, kic_feh
;;		readcol, '4zach/cool_KOIs.txt', KOI_KID, KOI_KOI, planet_epoch, planet_period, planet_a_over_rs, planet_rp_over_rs, planet_b, planet_duration, planet_depth, KOI_teff, KOI_logg
;
;		readcol, '4zach/number_of_stars.txt',  ns_KOI, ns_nstar, ns_rp, ns_flux
;		readcol, '4zach/tab5.txt', planet_KOI, planet_KID, planet_epoch, planet_period, planet_a_over_rs, planet_rp_over_rs, planet_b, planet_rp, planet_rp_ep, planet_rp_em, planet_flux, planet_flux_ep, planet_flux_em,  planet_KOI_teff, planet_KOI_radius
;
;		bumpy_pop_period = sss.period_sensitivity*0.0d
;		bumpy_pop_temperature = sss.temperature_sensitivity*0.0d
;		nstars_period =  sss.period_sensitivity*0.0d
;		transitprob_period =  sss.period_sensitivity*0.0d
;		nstars_temperature =  sss.temperature_sensitivity*0.0d
;		transitprob_temperature =  sss.temperature_sensitivity*0.0d
;
;			if keyword_set(bumpy) then factor = 2.5 else factor = 0.01
;			sigma_radius =0.0625*factor
;			sigma_period =0.25*factor
;			sigma_temperature =10.0*factor
;	
;		ns_period = ns_KOI
;		ns_a_over_rs = ns_KOI
;		for i=0, n_elements(ns_KOI)-1 do begin
;			i_match = where(planet_KOI eq ns_KOI[i], n_match)
;			if n_match ne 1 then stop
;			ns_period[i] = planet_period[i_match]
;			ns_a_over_rs[i] = planet_a_over_rs[i_match]
;		endfor
;		
;		
;		for i=0, n_elements(bumpy_pop_period[*,0])-1 do begin
;			for j=0, n_elements(bumpy_pop_period[0,*])-1 do begin
;				this_period = sss.period_axis[i]
;				this_radius = sss.radius_axis[j]
;				distance = ((planet_rp - this_radius)/sigma_radius)^2 + ((planet_period - this_period)/sigma_period)^2 
;				i_closest = where(distance eq min(distance))
;				i_closest = i_closest[0]
;				i_ns = where(ns_KOI eq planet_KOI[i_closest], n_match)
;				if n_match ne 1 then stop
;				i_ns = i_ns[0]
;			
;				nstars_period[i,j] = ns_nstar[i_ns]
;			;	transitprob_period[i,j] = 1.0/planet_a_over_rs[i_closest]
;			endfor
;		endfor
;		albedo = 0
;		planet_temperature = ((1.0 - albedo)/4.0)^0.25/planet_a_over_rs^0.5*planet_KOI_teff;planet_flux[i]^0.25*280;

;		ndetections_period = sss.period_sensitivity*0.0
;		ndetections_temperature = sss.temperature_sensitivity*0.0
;		for i=0, n_elements(planet_rp)-1 do begin
;			i_period = value_locate(sss.period_axis, planet_period[i])
;			i_temperature = value_locate(sss.temperature_axis, planet_temperature[i])
;			i_radius = value_locate(sss.radius_axis, planet_rp[i])
;			ndetections_period[i_period, i_radius] += planet_a_over_rs[i]
;			ndetections_temperature[i_temperature, i_radius] += planet_a_over_rs[i]
;		endfor
		
		if keyword_set(bumpy) then begin
				; read in Courtney's table
		readcol, '4zach/number_of_stars_rp_period_afterbug.txt',  ns_KOI, ns_rp, ns_period,  ns_nstar
		readcol, '4zach/tab5.txt', planet_KOI, planet_KID, planet_epoch, planet_period, planet_a_over_rs, planet_rp_over_rs, planet_b, planet_rp, planet_rp_ep, planet_rp_em, planet_flux, planet_flux_ep, planet_flux_em,  planet_KOI_teff, planet_KOI_radius

			 factor = 1.5; else factor = 0.01
			sigma_radius =0.0625*factor
			sigma_period =0.25*factor
			sigma_temperature =10.0*factor
		planet_nstars = planet_KOI*0.0
			bumpy_pop_period = sss.period_sensitivity*0.0d
		bumpy_pop_temperature = sss.temperature_sensitivity*0.0d
		for i=0, n_elements(planet_KOI)-1 do begin
			i_match = where(ns_KOI eq planet_KOI[i], n_match)
			if n_match ne 1 then stop
			planet_nstars[i] = ns_nstar[i_match]

			this_planet_radius = planet_rp[i]
			this_planet_period = planet_period[i]
			this_planet_a_over_rs = planet_a_over_rs[i]
			this_planet_nstars = planet_nstars[i]
			this_planet_temperature = 278.*(planet_flux[i]^0.25);((1.0 - albedo)/4.0)^0.25/planet_a_over_rs[i]^0.5*planet_KOI_teff[i];planet_flux[i]^0.25*280;
									
			;if this_planet_period gt max(sss.period_axis) or this_planet_radius lt min(sss.radius_axis) then continue;
			radius_weight = 1.0/sqrt(2*!pi)/sigma_radius*exp(-(sss.radius_grid - this_planet_radius)^2/sigma_radius^2/2.0)

			if this_planet_period ge min(sss.period_axis)  and this_planet_period le max(sss.period_axis) and this_planet_radius ge min(sss.radius_axis) and this_planet_radius le max(sss.radius_axis) then begin
				period_weight = 1.0/sqrt(2*!pi)/sigma_period*exp(-(sss.period_grid - this_planet_period)^2/sigma_period^2/2.0)
				bumpy_pop_period +=  period_weight*radius_weight/total(period_weight*radius_weight)*this_planet_a_over_rs/this_planet_nstars/sss.dlogperiod_grid/sss.dlogradius_grid
			endif

			if this_planet_temperature ge min(sss.temperature_axis)  and this_planet_temperature le max(sss.temperature_axis) and this_planet_radius ge min(sss.radius_axis) and this_planet_radius le max(sss.radius_axis) then begin
				temperature_weight = 1.0/sqrt(2*!pi)/sigma_temperature*exp(-(sss.temperature_grid - this_planet_temperature)^2/sigma_temperature^2/2.0)
				bumpy_pop_temperature +=  temperature_weight*radius_weight/total(temperature_weight*radius_weight)*this_planet_a_over_rs/this_planet_nstars/sss.dlogtemperature_grid/sss.dlogradius_grid
			endif
		endfor

			pop_period = bumpy_pop_period
			pop_temperature=bumpy_pop_temperature
			
		endif

		if ~keyword_set(bumpy) then begin	
;			x_initial = {k:1.0, r_0:1.5, sigma:0.5, beta:0.27, alpha:-1.92, g:1.0, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
;			params = struct_to_array(x_initial)
;			inputs = {nstars:nstars_period, ndetections:ndetections_period, period_grid:sss.period_grid, radius_grid:sss.radius_grid, x_initial:x_initial, dlogperiod_grid:sss.dlogperiod_grid, dlogradius_grid:sss.dlogradius_grid}
;			inputs = {pop_period:pop_period, nstars:nstars_period, ndetections:ndetections_period, period_grid:sss.period_grid, radius_grid:sss.radius_grid, x_initial:x_initial, dlogperiod_grid:sss.dlogperiod_grid, dlogradius_grid:sss.dlogradius_grid}
;			test = coolkoi_tominimize(params)

;			params = struct_to_array(x_initial)
;			fit = amoeba(0.001, function_name="coolkoi_tominimize", p0=params, scale=abs(params)/100.0)
;			coef = array_to_struct(fit, x_initial)
			restore, 'covariance_matrix.idl'
			coef = x_initial
			pop_period = analytical_df2dlogpdlogr(sss.period_grid, sss.radius_grid, coef=coef)
			restore, 'temperature_covariance_matrix.idl'
			coef = x_initial
			pop_temperature = analytical_df2dlogtdlogr(sss.temperature_grid, sss.radius_grid, coef=coef)

			;t = findgen(2000)+100
			;plot, planet_period, planet_temperature, psym=1
			;oplot, 365.0*((t/280.0)^4.0)^(-0.75), t
			; THE FACTOR of TWO BELOW IS A KLUDGE!
;			earth_relative_flux = (     2  *  sss.temperature_grid/280.0)^4.0
;			temp_period_grid = 365.0*(earth_relative_flux*1.0^(-1.0)*1.0^(2.0/3.0))^(-0.75)
;			pop_temperature = 3.0*analytical_df2dlogpdlogr(temp_period_grid, sss.radius_grid, coef=coef)*0.4/0.53
		endif	
;		ndetections_period = bumpy_pop_period*nstars_period*sss.dlogperiod_grid*sss.dlogradius_grid
	endif
	
	if keyword_set(coolkois) and keyword_set(weird) then begin
		plot=1
		pop_period = sss.period_sensitivity*0.0d
		pop_temperature = sss.temperature_sensitivity*0.0d
		
		
		
		upper_radius = 	[0.7, 	1.0, 	1.4, 	2.0, 	2.8, 	4.0, 	5.7, 	8.0, 	11.3, 	16.0, 	22.6]
		lower_radius =  [0.5, 	0.7, 	1.0, 	1.4, 	2.0, 	2.8, 	4.0, 	5.7, 	8.0, 	11.3, 	16.0]
		upper_logradius = alog10(upper_radius)
		lower_logradius = alog10(lower_radius)
		mid_logradius = (upper_logradius + lower_logradius)/2.0
		mid_logradius_grid = mid_logradius
		upper_period = [10.0, 	50.0]
		lower_period = [0.5, 	0.5]
		upper_logperiod = alog10(upper_period)
		lower_logperiod = alog10(lower_period)
		mid_logperiod = (upper_logperiod + lower_logperiod)/2.0
		mid_logperiod_grid = mid_logperiod
		dlogperiod_grid = (upper_logperiod - lower_logperiod)#ones(n_elements(mid_logradius))
		dlogradius_grid = ones(n_elements(mid_logperiod))#(upper_logradius - lower_logradius)

		distribution = [[0.032, 0.032],$
						[0.131,	0.194],$
						[0.118,	0.245],$
						[0.095,	0.211],$
						[0.028,	0.187],$
						[0.006,	0.006],$
						[0.004,	0.004],$
						[0.000,	0.000],$
						[0.003,	0.003],$
						[0.004,	0.004],$
						[0.003,	0.003]]

		top_errors =   [[0.0300,	0.0300],$
						[0.0414,	0.0540],$
						[0.0286,	0.0480],$
						[0.0279,	0.0462],$
						[0.0154,	0.0473],$
						[0.0088,	0.0088],$
						[0.0067,	0.0067],$
						[0.0000,	0.0000],$
						[0.0048,	0.0048],$
						[0.0059,	0.0059],$
						[0.0044,	0.0044]]
		
		bottom_errors =[[0.014,		0.014],$
						[0.030,		0.040],$
						[0.022,		0.038],$
						[0.021	,	0.036],$
						[0.010,	0.036],$
						[0.003,	0.003],$
						[0.002,	0.002],$
						[0.0000,	0.0000],$
						[0.002,	0.002],$
						[0.002,	0.002],$
						[0.001,	0.001]]		
						
		distribution += (top_errors - bottom_errors)/2.0	
		errors = (top_errors + bottom_errors)/2.0
						
	
		mid_logradius_grid = ones(n_elements(mid_logperiod))#mid_logradius
		mid_logperiod_grid = mid_logperiod#ones(n_elements(mid_logradius))


		x_initial = {k:1.0, r_0:1.5, sigma:0.5, beta:0.27, alpha:-1.92, g:1.0};, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
;		x_initial = {k:1.0, alpha:-1.92, beta:0.27, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}

		
	nexpected_period = nstars_period*analytical_df2dlogpdlogr(sss.period_grid, sss.radius_grid, coef=x_initial)
	stop
	help, nexpected_period^ndetections_period*exp(-nexpected_period)/factorial(ndetections_period)
	coef = array_to_struct(params, inputs.x_initial)

		p_initial = struct_to_array(x_initial)
		inputs = {mid_logradius_grid:mid_logradius_grid, mid_logperiod_grid:mid_logperiod_grid, distribution:distribution, x_initial:x_initial, mid_logperiod:mid_logperiod, mid_logradius:mid_logradius, errors:errors, upper_logperiod:upper_logperiod, lower_logperiod:lower_logperiod, upper_logradius:upper_logradius, lower_logradius:lower_logradius}
		test = df2_deviates(inputs=inputs)
		fit = mpfit('df2_deviates', p_initial, functargs={inputs:inputs})
		coef = array_to_struct(fit, x_initial)
	;	pop_period = coef.k*sss.radius_grid^coef.alpha*sss.period_grid^coef.beta*(1-exp(-(sss.period_grid/coef.P_0)^coef.gamma))
		pop_period = analytical_df2dlogpdlogr(sss.period_grid, sss.radius_grid, coef=coef)
		earth_relative_flux = (sss.temperature_grid/280.0)^4.0
		temp_period_grid = 365.0*(earth_relative_flux*1.0^(-1.0)*1.0^(2.0/3.0))^(-0.75)
		pop_temperature = 3.0*analytical_df2dlogpdlogr(temp_period_grid, sss.radius_grid, coef=coef)
		if keyword_set(plot) then begin
			stop
			xplot
			!p.multi=[0,1,2]
			top = max(distribution/dlogperiod_grid/dlogradius_grid)*1.3
			contour, distribution/dlogperiod_grid/dlogradius_grid, 10^mid_logperiod, 10^mid_logradius, yr=range(sss.radius_axis), xr=range(sss.period_axis), levels=findgen(100)/100*top, /fill, xs=3, ys=3
			contour, pop_period, sss.period_axis, sss.radius_axis, yr=range(sss.radius_axis), xr=range(sss.period_axis), levels=findgen(100)/100*top, /fill, xs=3, ys=3

			z = distribution/dlogperiod_grid/dlogradius_grid
			xplot
			!p.multi=[0,1,2]
			loadct, 39
			plot, [0], xr=[0,50], yr=[0.001, max(z)], xtitle='period', /ylog
			radius_colors = 254.0*indgen(n_elements(mid_logradius))/n_elements(mid_logradius)
			for i=0, n_elements(mid_logradius)-1 do plots, color=radius_colors[i], 10^mid_logperiod, z[*,i]
			for i=0, n_elements(sss.radius_axis)-1 do plots, color=interpol(radius_colors, 10^mid_logradius, sss.radius_axis[i]), sss.period_axis, pop_period[*,i]

			plot, [0], xr=[0,7], yr=[0.001, max(z)], xtitle='radius', /ylog
			for i=0, n_elements(mid_logperiod)-1 do plots, color=radius_colors, 10^mid_logradius, z[i,*], psym=-8
			for i=0, n_elements(sss.period_axis)-1 do plots, color=interpol(radius_colors, 10^mid_logradius, sss.radius_axis), sss.radius_axis, pop_period[i,*]
		

			stop
		endif

	
	endif

	if keyword_set(francois) then begin
		pop_period = sss.period_sensitivity*0.0d
		pop_temperature = sss.temperature_sensitivity*0.0d
		upper_radius = [22,6,4,2,1.25]
		lower_radius = [6,4,2,1.25, 0.8]
		upper_logradius = alog10(upper_radius)
		lower_logradius = alog10(lower_radius)
		mid_logradius = (upper_logradius + lower_logradius)/2.0
		mid_logradius_grid = mid_logradius
		upper_period = [2.0, 3.4, 5.9, 10, 17, 29, 50, 85, 145, 245, 418]
		lower_period = [ 0.8, 2.0, 3.4, 5.9, 10, 17, 29, 50, 85, 145, 245]
		upper_logperiod = alog10(upper_period)
		lower_logperiod = alog10(lower_period)
		mid_logperiod = (upper_logperiod + lower_logperiod)/2.0
		mid_logperiod_grid = mid_logperiod
		dlogperiod_grid = (upper_logperiod - lower_logperiod)#ones(n_elements(mid_logradius))
		dlogradius_grid = ones(n_elements(mid_logperiod))#(upper_logradius - lower_logradius)

		distribution = [[	0.015,	0.067,	0.17,	0.18,	0.27,	0.23,	0.35, 	0.71,	1.25,	0.94,	1.05],$
						[	0.004,	0.006,	0.11,	0.091,	0.29,	0.32,	0.49,	0.66,	0.43,	0.53,	0.24],$
						[	0.035,	0.18,	0.73,	1.93,	3.67,	5.29,	6.45,	5.25,	4.31,	3.09,	0.0],$
						[	0.17,	0.74,	1.49,	2.90,	4.30,	4.49,	5.29,	3.66,	6.54,	0.0,	0.0],$
						[	0.18,	0.61,	1.72,	2.70,	2.70,	2.93,	4.08,	3.46,	0.0,	0.0,	0.0]]/100.0;/dlogperiod_grid/dlogradius_grid/100.0

		errors	 = [[		0.007,	0.018,	0.03,	0.04,	0.06,	0.06,	0.10, 	0.17,	0.29,	0.28,	0.30],$
					[	0.003,	0.006,	0.03,	0.03,	0.07,	0.08,	0.12,	0.16,	0.17,	0.21,	0.15],$
					[	0.011,	0.03,	0.09,	0.19,	0.39,	0.64,	1.01,	1.05,	1.03,	0.90,	0.0],$
					[	0.03,	0.13,	0.23,	0.56,	0.73,	1.00,	1.48,	1.21,	2.20,	0.0,		0.0],$
					[	0.04,	0.15,	0.43,	0.60,	0.83,	1.05,	1.88,	2.81,	0.0,		0.0,		0.0]]/100.0;/dlogperiod_grid/dlogradius_grid/100.0

		mid_logradius_grid = ones(n_elements(mid_logperiod))#mid_logradius
		mid_logperiod_grid = mid_logperiod#ones(n_elements(mid_logradius))

;		x_initial = {k:1.0, r_0:1.5, sigma:1.0, beta:0.27, alpha:-1.92, g:1.0};, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}

		x_initial = {k:1.0, r_0:1.5, sigma:0.5, beta:0.27, alpha:-1.92, g:1.0, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
;		x_initial = {k:1.0, alpha:-1.92, beta:0.27, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
		p_initial = struct_to_array(x_initial)
		inputs = {mid_logradius_grid:mid_logradius_grid, mid_logperiod_grid:mid_logperiod_grid, distribution:distribution, x_initial:x_initial, mid_logperiod:mid_logperiod, mid_logradius:mid_logradius, errors:errors, upper_logperiod:upper_logperiod, lower_logperiod:lower_logperiod, upper_logradius:upper_logradius, lower_logradius:lower_logradius}
		test = df2_deviates(inputs=inputs)
		fit = mpfit('df2_deviates', p_initial, functargs={inputs:inputs})
		coef = array_to_struct(fit, x_initial)
	;	pop_period = coef.k*sss.radius_grid^coef.alpha*sss.period_grid^coef.beta*(1-exp(-(sss.period_grid/coef.P_0)^coef.gamma))
		pop_period = analytical_df2dlogpdlogr(sss.period_grid, sss.radius_grid, coef=coef)
		earth_relative_flux = (sss.temperature_grid/280.0)^4.0
		temp_period_grid = 365.0*(earth_relative_flux*1.0^(-1.0)*1.0^(2.0/3.0))^(-0.75)
		pop_temperature = 3.0*analytical_df2dlogpdlogr(temp_period_grid, sss.radius_grid, coef=coef)
		if keyword_set(plot) then begin
			xplot
			!p.multi=[0,1,2]
			top = max(distribution/dlogperiod_grid/dlogradius_grid)*1.3
			contour, distribution/dlogperiod_grid/dlogradius_grid, 10^mid_logperiod, 10^mid_logradius, yr=range(sss.radius_axis), xr=range(sss.period_axis), levels=findgen(100)/100*top, /fill, xs=3, ys=3
			contour, pop_period, sss.period_axis, sss.radius_axis, yr=range(sss.radius_axis), xr=range(sss.period_axis), levels=findgen(100)/100*top, /fill, xs=3, ys=3

			z = distribution/dlogperiod_grid/dlogradius_grid
			xplot
			!p.multi=[0,1,2]
			loadct, 39
			plot, [0], xr=[0,50], yr=[0.001, max(z)], xtitle='period', /ylog
			radius_colors = 254.0*indgen(n_elements(mid_logradius))/n_elements(mid_logradius)
			for i=0, n_elements(mid_logradius)-1 do plots, color=radius_colors[i], 10^mid_logperiod, z[*,i]
			for i=0, n_elements(sss.radius_axis)-1 do plots, color=interpol(radius_colors, 10^mid_logradius, sss.radius_axis[i]), sss.period_axis, pop_period[*,i]

			plot, [0], xr=[0,7], yr=[0.001, max(z)], xtitle='radius', /ylog
			for i=0, n_elements(mid_logperiod)-1 do plots, color=radius_colors, 10^mid_logradius, z[i,*], psym=-8
			for i=0, n_elements(sss.period_axis)-1 do plots, color=interpol(radius_colors, 10^mid_logradius, sss.radius_axis), sss.radius_axis, pop_period[i,*]
			stop

		endif
	endif


	
	return, {period:pop_period, temperature:pop_temperature}

END


FUNCTION coolkoi_tominimize, params
		common fitting_vars
		coef = array_to_struct(params, inputs.x_initial)
		deviates = (inputs.pop_period) - (analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef) > 0)
	;	nexpected_period = inputs.nstars*analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef)*inputs.dlogperiod_grid*inputs.dlogradius_grid; > 0
	;	if total(finite(nexpected_period, /nan)) gt 0 or min(nexpected_period) lt 0 then return, 1e6
	;	nexpected_period = nexpected_period/(inputs.ndetections > 0.1)
	;	ndetections_period = inputs.ndetections/(inputs.ndetections > 0.1)
	;	likelihoods = nexpected_period^ndetections_period*exp(-nexpected_period);/factorial(ndetections_period)
		i = where(inputs.radius_grid gt 1.25 and inputs.radius_grid lt 4.0 and inputs.period_grid lt 50 )
	;	tominimize= -total(alog10(likelihoods[i])) 
		!p.multi=[0,1,3]
;		loadct, 39
;		plot, i, nexpected_period[i]
;		oplot, inputs.nstars*analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef)*inputs.dlogperiod_grid*inputs.dlogradius_grid > 0, color=150
;		plot, i, inputs.ndetections[i]
;		plot, i, likelihoods[i]
		tominimize = total(deviates[i])^2
		levels = findgen(30)/30*max(inputs.pop_period)
		plot, inputs.pop_period
		plot, (analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef) > 0)
		plot, deviates
		print, tominimize
	
		return, tominimize
END


; The columns in "cool_stars.txt" are:
;1) KID
;2) Revised Teff (K)
;3) Revised radius (Rsun)
;4) Revised mass (Msun)
;5) Revised surface gravity (log cgs)
;6) Revised [Fe/H]
;7) Revised luminosity (Lsun)
;8) (very rough) photometric distance
;9) KIC Teff (K)
;10) KIC Rs (Rsun)
;11) KIC surface gravity (log cgs)
;12) KIC [Fe/H]
;
;The columns in cool_KOIs.txt are:
;1) KID
;2) KOI
;3) Revised time of transit center (days; sometimes folded to transit period)
;4) Revised period (days)
;5) Revised a/Rstar
;6) Revised Rp/Rstar
;7) Revised impact parameter
;8) Revised transit duration (hours)
;9) Revised depth (ppm)
;10) Revised teff (K)
;11) Revised surface gravity (log cgs)