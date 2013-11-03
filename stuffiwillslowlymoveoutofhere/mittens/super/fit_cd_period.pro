FUNCTION r_disc_model_period, radius, period, coefs=coefs
	return, exp(coefs.constant + coefs.radius*alog(radius) + coefs.period*alog(period))
END

PRO update_period_cov
	c = merge_chains(search="fitcd_trimmedsuperneptune_*", maxlikely=x_initial)
	covariance_matrix = cov_matrix(c, indgen(6))
	save, filename='covariance_matrix.idl', covariance_matrix, x_initial
END

FUNCTION negativeloglikelihood_period, params
	common fitting_vars_period, inputs, plot
	coef = array_to_struct(params, inputs.x_initial)
	if min(params) lt 0 then return, 100000.0
	population_period = analytical_df2dlogpdlogr(inputs.period_grid, inputs.radius_grid, coef=coef)*inputs.dlogperiod_grid*inputs.dlogradius_grid
	median_density_ratio = median((1.0/inputs.koi.a_over_rs*(inputs.koi.period/10.)^(2./3.)/.051)^(-3.0))
	transit_prob =0.051*(10.0/inputs.period_grid)^(2.0/3.0)*median_density_ratio^(-1.0/3.0)
	r_fine = r_disc_model_period(inputs.radius_grid, inputs.period_grid, coef=inputs.disc_coef)
	disc_prob = r_fine/(1.0+r_fine)
	nexpected_period = population_period*transit_prob*disc_prob*3897.0
	ndetected_period = inputs.ndetected_period

	if keyword_set(plot) then begin
		!p.multi=[0,3,3]	
		KOI = inputs.KOI
		xlog = 0
		ylog = 0
		r = r_disc_model_period(KOI.rp, KOI.period, coef=inputs.disc_coef)
		eta = r/(1.0+r)
		
		i = sort(KOI.rp)
		cumu = total(/cumu, KOI[i].a_over_rs/eta[i])
		plot, koi[i].rp, ((cumu[1:*]-cumu)/(koi[i[1:*]].rp -  koi[i].rp))*koi[i].rp/3897, xr=[0.5, 4], /xlog, /ylog
		oplot, inputs.radius_axis, total(population_period, 1)*inputs.radius_axis, thick=5

		i = sort(KOI.period)
		cumu = total(/cumu, KOI[i].a_over_rs/eta[i])
		plot, koi[i].period, ((cumu[1:*]-cumu)/(koi[i[1:*]].period -  koi[i].period))*koi[i].period/3897, /xlog, /ylog
		oplot, inputs.period_axis, total(population_period, 2)*inputs.period_axis, thick=5
	
	
		plot, nexpected_period, ndetected_period, psym=-8, /iso

	
		; plot detection efficiency
		contour, transit_prob*disc_prob, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /nodata, xs=3, ys=3, xlog=xlog, ylog=ylog
		loadct, file='~/zkb_colors.tbl', 55
		contour, transit_prob*disc_prob, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over



		; plot inferred population
		loadct, file='~/zkb_colors.tbl', 0
		contour, population_period, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /nodata, xs=3,ys=3, xlog=xlog, ylog=ylog
		loadct, file='~/zkb_colors.tbl', 55
		loadct, file='~/zkb_colors.tbl', 47
		contour,  population_period, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over
		loadct, file='~/zkb_colors.tbl', 0
		r = r_disc_model_period(KOI.rp, KOI.period, coef=inputs.disc_coef)
		eta = r/(1.0+r)
		symsize = sqrt(KOI.a_over_rs/eta)
		symsize = symsize/max(symsize)*10
		theta = findgen(21)/!pi
		usersym, cos(theta), sin(theta)
		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=symsize[i], psym=8, noclip=0
		oplot, inputs.period_axis,  coef.b/(1.0 + (coef.pfunny/inputs.period_axis)^coef.beta) 

;/inputs.dlogperiod_grid/inputs.dlogradius_grid
		; plot expected detections
		loadct, file='~/zkb_colors.tbl', 0
		contour, nexpected_period, inputs.period_axis, inputs.radius_axis, /fill,ys=3, nlevels=100, /nodata, xs=3, xlog=xlog, ylog=ylog
		loadct, file='~/zkb_colors.tbl', 55
		loadct, file='~/zkb_colors.tbl', 45
		contour, nexpected_period, inputs.period_axis, inputs.radius_axis, /fill, nlevels=100, /over
		KOI = inputs.KOI
		loadct, file='~/zkb_colors.tbl', 0
		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=1, psym=8, noclip=0	

	
	endif
	logprobs = ndetected_period*alog(nexpected_period)+(-nexpected_period)
	negativeloglike = -total(logprobs, /double)
	
	if keyword_set(plot) then begin
		plot, inputs.period_grid, logprobs, /xlog, psym=8
		plot, inputs.radius_grid, logprobs, /xlog, psym=8
		print, negativeloglike
		print_struct, coef
	endif	
	if keyword_set(plot) then begin
		plothist, logprobs, /ylog
	endif
	return, negativeloglike
	
END

PRO fit_cd_period, n
	
		common fitting_vars_period
		; load up the sensitivity estimate (mostly for having the grids available)
;		if file_test('statpaper_1_phased_data.idl') eq 0 or keyword_set(remake) then s_1actual = simulate_a_season(1, /phased, /errors, /actual)
;		restore, 'statpaper_1_phased_data.idl'	
		
			t_lastplot = 0
	spawn, 'hostname', hostname
	prefix = strcompress(/remo, string(date_conv(systime(/jul), 'R'),format='(f15.5)')) + '_'
seed = systime(/sec)
	; set up grid
	n_radii = 100
	n_periods = 500
	n_temperatures = n_periods
	if keyword_set(radius_range) then begin
		min_radius = float(min(radius_range))
		max_radius = float(max(radius_range))
	endif else begin
		min_radius = 0.8;min(simulated_sensitivity.radii)
		max_radius = 4.5
	endelse
	dlogradius = (alog(max_radius)- alog(min_radius))/(n_radii-1)
	radius_grid = ones(n_periods)#(min_radius*exp(findgen(n_radii)*dlogradius))
	dlogradius_grid = dlogradius*(1.0 + 0.0*radius_grid)*alog10(exp(1))
	radius_axis = (min_radius*exp(findgen(n_radii)*dlogradius))
	if keyword_set(period_range) then begin
		min_period = float(min(period_range))
		max_period = float(max(period_range))
	endif else begin
		min_period = 0.25
		max_period = 50.0
	endelse
	dlogperiod = (alog(max_period)- alog(min_period))/(n_periods-1)
	period_grid =(min_period*exp(findgen(n_periods)*dlogperiod))#ones(n_radii)
	dlogperiod_grid = dlogperiod*(1.0 + 0.0*period_grid)*alog10(exp(1))
	period_axis = (min_period*exp(findgen(n_periods)*dlogperiod))
	if keyword_set(temperature_range) then begin
		min_temperature = float(min(temperature_range))
		max_temperature = float(max(temperature_range))
	endif else begin
		min_temperature = 250.0
		max_temperature = 1000.0
	endelse
	dtemperature = (max_temperature- min_temperature)/(n_temperatures-1.0)
	temperature_grid = (min_temperature + findgen(n_temperatures)*dtemperature)#ones(n_radii)
	dlogtemperature_grid = dtemperature/temperature_grid*alog10(exp(1))
	temperature_axis =(min_temperature + findgen(n_temperatures)*dtemperature)

	supersampled = {period_sensitivity:period_grid*0.0,$
						temperature_sensitivity:temperature_grid*0.0, $
						radius_grid:radius_grid, dlogradius_grid:dlogradius_grid, radius_axis:radius_axis, dlogradius:dlogradius,$
						period_grid:period_grid, dlogperiod_grid:dlogperiod_grid, period_axis:period_axis, dlogperiod:dlogperiod,$
						temperature_grid:temperature_grid, dlogtemperature_grid:dlogtemperature_grid, temperature_axis:temperature_axis, dtemperature:dtemperature}

		; read in Courtney's table
		readcol, '4zach/number_of_stars_rp_period_afterbug.txt',  ns_KOI, ns_rp, ns_period,  ns_nstar
		readcol, '4zach/tab5.txt', planet_KOI, planet_KID, planet_epoch, planet_period, planet_a_over_rs, planet_rp_over_rs, planet_b, planet_rp, planet_rp_ep, planet_rp_em, planet_flux, planet_flux_ep, planet_flux_em,  planet_KOI_teff, planet_KOI_radius

		eta_disc = ns_nstar/3897.0
		r_disc = eta_disc/(1-eta_disc)
		ns_temperature = ns_KOI*0.0
		ns_a_over_rs = ns_KOI*0.0
		for i=0, n_elements(ns_KOI)-1 do begin
			i_match = where(planet_KOI eq ns_KOI[i], n_match)
			if n_match ne 1 then stop
			ns_temperature[i] = 278*(planet_flux[i_match])^0.25
			ns_a_over_rs[i] = planet_a_over_rs[i_match]
		endfor
		
		i_ok = where(ns_rp lt max_radius and r_disc lt 30)
		KOI = struct_conv({KOI:ns_KOI, period:ns_period, rp:ns_rp, nstar:ns_nstar, temperature:ns_temperature, a_over_rs:ns_a_over_rs, eta_disc:eta_disc, r_disc:r_disc})
		trimmed_KOI = KOI[i_ok]		

		
		xplot
		!p.multi=[0,2,4]
		loadct, 39
		plot, trimmed_KOI.period, trimmed_KOI.r_disc, /nodata, /ylog, /xlog, yr=[0.1, 300]
		plots, trimmed_KOI.period, trimmed_KOI.r_disc, psym=8, color=trimmed_KOI.rp/3*254., symsize=1
		loadct, 0
		plot, trimmed_KOI.rp, trimmed_KOI.r_disc, /nodata, /ylog, yr=[0.1, 300], /xlog, xr=[0.5, 6]
		plots, trimmed_KOI.rp, trimmed_KOI.r_disc, psym=8, color=alog(trimmed_KOI.period)/max(alog(trimmed_KOI.period))*254., symsize=1
		
		input_period = alog(transpose([[trimmed_KOI.rp],[trimmed_KOI.period]]))
		fit = regress(input_period, alog(trimmed_KOI.r_disc), ones(n_elements(trimmed_KOI.r_disc)), yfit, const, Sigma, Ftest, R, Rmul, Chisq, Status, /relative)
		disc_coef = {constant:const, radius:fit[0], period:fit[1]}


		
	;	KOI = KOI[where(KOI.rp lt 4.5 and KOI.rp gt 0.8)]
		;populate a grid with detections
		ndetected_period = supersampled.period_sensitivity*0.0d
		ndetected_temperature = supersampled.temperature_sensitivity*0.0d
		for i=0, n_elements(KOI)-1 do begin
			i_period = value_locate(supersampled.period_axis, KOI[i].period)
			i_temperature = value_locate(supersampled.temperature_axis, KOI[i].temperature)
			i_radius = value_locate(supersampled.radius_axis, KOI[i].rp)
			if i_radius lt (n_elements(supersampled.radius_axis) -1) and i_radius gt 0 then begin
				if i_period lt (n_elements(supersampled.period_axis) -1) and i_period gt 0 then ndetected_period[i_period, i_radius] += 1
				if i_temperature lt (n_elements(supersampled.temperature_axis) -1) and i_temperature gt 0 then ndetected_temperature[i_temperature, i_radius] += 1
				print, i_radius,  (n_elements(supersampled.radius_axis) -1)
			endif
		endfor
		
		cleanplot
		xplot, 2
		!p.multi=[0,2,1]
		plot, /nodata, KOI.period, KOI.rp, yr=[0.5, 4], /xlog, ys=3
		r = koi.r_disc;r_disc_model_period(KOI.rp, KOI.period, coefs=coefs)
		eta = r/(1.0+r)
		symsize = sqrt(KOI.a_over_rs/eta)
		symsize = symsize/max(symsize)*10
		theta = findgen(21)/!pi
		usersym, cos(theta), sin(theta)


		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=symsize[i], psym=8
		plot, /nodata, KOI.period, KOI.rp, yr=[0.5, 4], /xlog, ys=3
		r = r_disc_model_period(KOI.rp, KOI.period, coef=disc_coef)
		eta = r/(1.0+r)
		symsize = sqrt(KOI.a_over_rs/eta)
		symsize = symsize/max(symsize)*5
		theta = findgen(21)/!pi
		usersym, cos(theta), sin(theta)
		for i=0, n_elements(KOI)-1 do plots, KOI[i].period, KOI[i].rp, symsize=symsize[i], psym=8


		
		xplot, xsize=1000, ysize=500
		; FITTING WITH AMOEBA!
	;	x_initial = {k:1.0, r_0:1.5, sigma:0.5, beta:0.27, alpha:-1.92, g:1.0, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
		x_initial = {a:0.337, alpha:0.44, b:2.0, beta:2.0, c:0.43, pfunny:2.0};, sigma:0.1, p0:1.0};, sigma:0.5, beta:0.27, alpha:-1.92, g:1.0, P_0:7.0, gamma:2.6};, k2:-0.5, alpha2:-1.0}
		params = struct_to_array(x_initial)
		inputs = {ndetected_period:ndetected_period, period_grid:supersampled.period_grid, radius_grid:supersampled.radius_grid, period_axis:supersampled.period_axis, radius_axis:supersampled.radius_axis, x_initial:x_initial, dlogperiod_grid:supersampled.dlogperiod_grid, dlogradius_grid:supersampled.dlogradius_grid, KOI:KOI, disc_coef:disc_coef}

;		fit = amoeba(0.001, function_name="negativeloglikelihood_period", p0=params, scale=abs(params)/100.0)
;;;;;;;;;;;;;;;;;;;;;;
		n_parameters = n_elements(params)
		if file_test('covariance_matrix.idl') then restore, 'covariance_matrix.idl' else begin
			covariance_matrix = dblarr(n_parameters, n_parameters)
			i = indgen(n_parameters)
			covariance_matrix[i,i] = (abs(params)/50.0)^2
		endelse
			mvg = draw_mvg(struct_to_array(x_initial), covariance_matrix, n)
			fake_chain = replicate(x_initial, n)
			for i=0, n_tags(fake_chain)-1 do fake_chain.(i) = reform(mvg[i,*])
		i_varying = where(covariance_matrix[indgen(n_parameters), indgen(n_parameters)] ne 0, n_varying_parameters)
		temp = covariance_matrix[i_varying,*]
		varying_covariance_matrix = temp[*,i_varying]
		decomposition = cholesky(varying_covariance_matrix/10.0)


	; create and zero out a chain
	chain = replicate(x_initial, n)
	for i=0, n_tags(chain)-1 do chain[1:*].(i) = 0
	loglikelihood = fltarr(n)
	was_accepted = bytarr(n)

	; transition to a fairly random place
	chain[0] = mcmc_transition(x_initial, seed, decomposition*4, i_varying)
	
		; set up diagnostic plot windows
		clear
		cleanplot

	save, filename='cdperiod_inputs.idl'
	xplot, title='Covariances', xsize=600, ysize=600, 1
	xplot, title='Chains', xsize=300, ysize=600, 2
	xplot, title='Acceptance Rate', xsize=300, ysize=200, 3
	xplot, title='Model Fit', xsize=700, ysize=500, 4

	; run chain
	for i=0l, n-1 do begin

		; propose a new step
		proposed = mcmc_transition(chain[i-1 > 0], seed, decomposition, i_varying)
		; find the deviates + loglikelihood for this step
		proposed_loglikelihood = -negativeloglikelihood_period(struct_to_array(proposed))

		; decide whether or not to keep proposed jump
		if mcmc_accept(proposed_loglikelihood, loglikelihood[i-1 > 0], see) or i eq 0 then begin
			chain[i] = proposed
			loglikelihood[i] = proposed_loglikelihood
			was_accepted[i] = 1B
		endif else begin
			chain[i] = chain[i-1]
			loglikelihood[i] = loglikelihood[i-1]
		endelse
		plot =0
		if i mod (n/50 < 1000) eq 0 and i gt 0 then begin
			print, rw(i), ' / ', rw(n), ' completed at ', systime()
	;		counter, i, n, /timeleft, 'completed: ', starttime=starttime
			if systime(/sec) - t_lastplot gt 5 then begin
				
				wset, 1
				plot_ndpdf, create_struct('GUESS', fake_chain[0:i], 'MCMC', chain[0:i]), psym=3, /mult, fried=(i gt 10000), res=15

				;plot_ndpdf, chain[0:i], psym=3, fried=(i gt 10000), res=15
				!x.margin=[10,2]
				wset, 2
				erase
							!p.charsize=1.5
				!p.charthick=1
				!y.margin=[2,7]
				plot_struct, chain[0:i], xs=7, ys=3
				!y.margin=[2,2]
	
				smultiplot, [1,n_parameters+1], /init
				smultiplot
				plot, loglikelihood[0:i], xs=7, ys=3, psym=8, /noerase, ytitle='log(likeli)'
				smultiplot, /def
								wset, 3
				!y.margin=[4,2]
				!x.margin=[10,3]
				plothist, was_accepted, title=string(total(was_accepted, /doub)/n_elements(was_accepted)*100, form='(F4.1)') + '%'
			
				loadct, 39
				t_lastplot = systime(/sec)
				wset, 4
				plot = 1
			endif
		end
	;	print, proposed_loglikelihood, loglikelihood[i], was_accepted[i], systime(/sec) - t
	endfor
	if n gt 1000 then	save, chain, loglikelihood, was_accepted, filename='fitcd_trimmedsuperneptune_'+prefix+'_chain.idl'
	plot = 1
	c = merge_chains(search='fitcd_trimmedsuperneptune_*', maxlikely=best)
	set_plot, 'ps'
	device, filename='cd_period_bestfit.eps', xsize=14, ysize=10, /inches, /encap, /colo
	s = negativeloglikelihood_period(struct_to_array(best))
	device, /close
	epstopdf, 'cd_period_bestfit.eps'
	
;	if question("Chain's done! Want to poke around?", /int) then stop


	;	coef = array_to_struct(fit, x_initial)
	;	save, coef, filename='coolkoi_modelfit.idl'

END