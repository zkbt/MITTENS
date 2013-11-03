PRO lcogt_sim, seed, eps=eps
	restore, 'lcogt_expectation.idl'
	
	
	lengths = findgen(20)+1
	fraction_detection = fltarr(20)
	n_lengths = n_elements(lengths)
	n_iterations = 5000
	while(n_elements(planets) lt n_iterations) do begin
		indices = randomu(seed, 2)*size(/dim, period_expectation)
		prob = period_expectation[indices[0], indices[1]]/max(period_expectation)
		if randomu(seed) lt prob then begin
			planet = {radius:supersampled.radius_grid[indices[0], indices[1]], period:supersampled.period_grid[indices[0], indices[1]], hjd0:randomu(seed)*100.0, inclination:!pi/2.0}
			star = {radius:0.20, mass:0.18, imag:12.0}
			if n_elements(planets) eq 0 then planets = planet else planets = [planets, planet]
			if n_elements(stars) eq 0 then stars = star else stars = [stars, star]
		endif
		counter, n_elements(planets), n_iterations
	endwhile
	sns = fltarr(n_iterations, n_lengths)
	;for i=0, n_iterations-1 do	sns[i] = didwedetect(planets[i], stars[i], eps=i eq 0, plot=i eq 0, seed=(seed+1))
	for j=0, n_elements(lengths)-1 do begin
		for i=0, n_iterations-1 do begin
			sns[i, j] = didwedetect(planets[i], stars[i], eps=0, plot=0, seed=seed, camp=lengths[j])
		endfor
		fraction_detection[j] = total(sns[*,j] gt 10 and planets.radius gt 1.8)/total(planets.radius gt 1.8)
		xplot
		plot, lengths, fraction_detection
		print, j, n_elements(lengths)
	endfor
	
	set_plot,'ps'
	device, filename='optimum_campaign_length.eps', /encapsulated, /color, xsize=3.5, ysize=2.5, /inches
	!p.charsize=0.8
	plot, lengths, fraction_detection, xtitle='Length of LCOGT Follow-up Campaign (days)', ytitle='Fraction of MEarth!CCandidates Confirmed', xs=3, thick=5
	xyouts, align=1.0, 20, 0.08,'(assuming 50% weather losses)'
	device, /close
	set_plot, 'x'
	epstopdf, 'optimum_campaign_length.eps'
	stop
END

FUNCTION didwedetect, planet, star, eps=eps, seed=seed, plot=plot, campaign_duration=campaign_duration

	@planet_constants
	if ~keyword_set(campaign_duration) then campaign_duration = 10.0
	n_fine = 10000.0
	fine_hjd = findgen(n_fine)/n_fine*campaign_duration
	fine_transit = 	-2.5*alog10(zeroeccmodel(fine_hjd,planet.hjd0,planet.period,star.mass,star.radius,planet.radius*r_earth/r_sun,planet.inclination,0.0,0.24,0.38) )
	
	weather_losses = 0.50
	weather_gaps = (randomu(seed, 100)*5 + 2.0)/24.0
	average_weather_gaps = mean(weather_gaps)
	n_weather_gaps = round(float(campaign_duration*weather_losses)/average_weather_gaps)
	
	noise = 1.0/500.0
	t_readout = 5.0/60.0/60.0/24.0
	t_pointing = 60.0/60.0/60.0/24.0
	t_exp = 10.0/60.0/60.0/24.0
	n_exp = 5
	n_stars = 4
	
	; make timestamps for one star
	stamps_onepointing = findgen(n_exp)*(t_exp+t_readout)
	stamps_onestar = stamps_onepointing
	n_pointings=0
	while (max(stamps_onestar) lt campaign_duration) do begin
		stamps_onestar = [stamps_onestar, stamps_onepointing+n_stars*n_exp*(t_readout + t_exp + t_pointing)*n_pointings]
		n_pointings+=1
	endwhile
	; add weather gaps
	bad = bytarr(n_elements(stamps_onestar))
	for i=0, n_weather_gaps-1 do begin
		start_of_bad = stamps_onestar[randomu(seed)*n_elements(stamps_onestar)]
		duration_of_bad = weather_gaps[randomu(seed)*n_elements(weather_gaps)]
		i_bad = where(stamps_onestar gt start_of_bad and stamps_onestar lt (start_of_bad + duration_of_bad), complement=i_ok, n_bad)
		stamps_onestar = stamps_onestar[i_ok]
	endfor
	;print, n_elements(stamps_onestar)/n_exp, ' / ', n_pointings, ' === ', float((n_pointings - n_elements(stamps_onestar)/n_exp))/n_pointings, ' losses'
	
	; make timestamps for all stars
	stamps_stars = stamps_onestar
	for i=1, n_stars-1 do stamps_stars = [[stamps_stars],[stamps_onestar+i*n_exp*(t_readout + t_exp + t_pointing)]]
	noiseless_stars = 0.0*stamps_stars
	noises = 0.0025*[1, 1, 1, 1];randomn(seed, n_stars)*0.0005 + 0.003 > 0.002
	
	; inject one transit
	i_lucky = fix(randomu(seed)*n_stars)
	noiseless_stars[*,i_lucky] = interpol(fine_transit, fine_hjd, stamps_onestar)
	i_int = where(interpol(fine_transit, fine_hjd, stamps_onestar) gt -2.5*alog10(1-(planet.radius*r_earth/r_sun/star.radius)^2.0), n_int)

	; simulate the noise
	simulated_stars = noiseless_stars
	for i=0, n_stars-1 do simulated_stars[*,i] += randomn(seed, n_elements(stamps_onestar))*noises[i]

	if n_int gt 0 then begin
		measured_depth = total(simulated_stars[i_int,i_lucky]/noise^2)/(n_int/noise^2)
		measured_noise = noise/sqrt(n_int)/0.8
		sn =  measured_depth/measured_noise
		t_atransit = stamps_stars[i_int[randomu(seed)*n_int], i_lucky]
		zoomin = t_atransit + [-6.0, 6.0]/24.0
	endif else sn = 0.0
	
	; skip the complicated stuff
	if ~keyword_set(plot) then return, sn
	
	
	
	if n_int gt 0 then print, "SIGNAL TO NOISE = ", measured_depth, measured_noise, sn
	
	
	cts = [52, 42, 54, 60, 62]
	!p.charsize=0.75
	xr = [0, campaign_duration]
	yr = [0.014, -0.014]
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename = 'lcogt_followup_zoomout.eps'
		device, filename=filename, /encap, /color, xsize=7.5, ysize=3, /inches
	endif else 	xplot, 1, xsize=500, ysize=300

	smultiplot, [1,n_stars], /init, ygap=0.005
	;zoomed out
	for i=0, n_stars-1 do begin
		smultiplot, dox=i eq (n_stars-1)
		if i eq 0 then title='Simulated LCOGT Follow-up of Single-Transit MEarth Candidates' else title=''
		if i eq 2 then ytitle='       Relative Flux (mag.)' else ytitle=''
		if i eq n_stars-1 then xtitle = 'Time (days)' else xtitle = ''
		loadct, 0
		plot, [0], xr=xr, yr=yr, xs=3, ys=3, xtitle=xtitle, ytitle=ytitle, title=title
		if i eq i_lucky then oplot, fine_hjd+ i*n_exp*(t_readout + t_exp + t_pointing), fine_transit else hline, 0
		loadct, file='~/zkb_colors.tbl', cts[i]
		oplot, stamps_stars[*,i], simulated_stars[*,i], psym=8, symsize=0.3, color=150
		loadct, 0
		if n_int gt 0 then vline, zoomin, linestyle=2
	endfor
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
	
	
	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename = 'lcogt_followup_zoomin.eps'
		device, filename=filename, /encap, /color, xsize=7.5, ysize=3, /inches
	endif else 	xplot, 2, xsize=500, ysize=300

	smultiplot, [2,n_stars], /init, /rowm, colw=[1, 0.25], ygap=0.005
	
	;zoomed in
	xr = zoomin
	plot, [0], xs=4, ys=4
	for i=0, n_stars-1 do begin
		smultiplot
		if i eq 2 then ytitle='       Relative Flux (mag.)' else ytitle=''
		if i eq n_stars-1 then xtitle = 'Time (days)' else xtitle = ''
		loadct, 0
		plot, [0], xr=xr, yr=yr, xs=3, ys=3, xtitle=xtitle, ytitle=ytitle
		
		
		if i eq i_lucky then oplot, fine_hjd + i*n_exp*(t_readout + t_exp + t_pointing), fine_transit else hline, 0
		loadct, file='~/zkb_colors.tbl', cts[i]
		oplot, stamps_stars[*,i], simulated_stars[*,i], psym=8, symsize=0.3, color=150

		plot_binned, stamps_stars[*,i], simulated_stars[*,i], n_bins=n_pointings, yr=yr, xs=3, xr=xr, /over, /sem, fixerr=noises[i_lucky]/sqrt(n_exp), psym=8, symsize=0.3, /justbin, errcolor=1
	endfor

	
		!p.charsize=0.8

	smultiplot
	plot, [0,1], [0, 1], xs=4, ys=4, /nodata
	loadct, 0
	xyouts, 0.6, 0.75, '(zoom of above)', align=0.5, charthick=3
	smultiplot
	plot, [0,1], [0, 1], xs=4, ys=4, /nodata

	str = 'Star:'
	str += goodtex('!C  '+rw(string(form='(F5.2)', star.radius)) + 'R_{'+ zsymbol(/sun) +'} radius')
	str += goodtex('!C  ' + rw(string(form='(F5.2)', star.mass)) + 'M_{'+ zsymbol(/sun) +'} mass')
	str += goodtex('!C  I_{C} =  ' + rw(string(form='(F5.1)', star.imag)) + ' mag.')
	str += '!C!C'
	
	str += 'Planet:'
	str += goodtex('!C  ' + rw(string(form='(F5.2)', planet.radius)) + 'R_{'+ zsymbol(/earth) +'} radius')
	str += goodtex('!C  ' + rw(string(form='(F5.2)', planet.period)) + ' day period')
	str += '!C!C'

	
	str += 'Transit Detected at:'
	str += goodtex('!C     ' + rw(string(sn, form='(F4.1)')) + '\sigma')
	loadct, cts[i_lucky], file='~/zkb_colors.tbl'
	xyouts, 0.1, 0.5, str
	
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
	
	return, sn
END