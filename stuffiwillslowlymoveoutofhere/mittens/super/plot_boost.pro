PRO plot_boost, eps=eps
	n = 50
	a = findgen(n)/n*0.02
	boost = fltarr(n)
	for i=0, n-1 do boost[i] = guess_inclination(a[i])

	boost_cautious = fltarr(n)
	for i=0, n-1 do boost_cautious[i] = guess_inclination(a[i], soften=10)

	boost_really_cautious = fltarr(n)
	for i=0, n-1 do boost_really_cautious[i] = guess_inclination(a[i], soften=100)

	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename='spots/boost.eps', /encap
	endif
	cleanplot
	loadct, 39
	plot, a, boost, psym=-8
	oplot, a, boost_cautious, psym=-8, color=50
	oplot, a, boost_really_cautious, psym=-8, color=250

	al_legend, /bottom, /right, ['Bold', 'Cautious', 'Cautious-er'], linestyle=0, color=[0,50,250], psym=-8, box=0

	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, 'spots/boost.eps'
	endif
	amplitude = a
	save, filename='spot_transit_boost.idl', amplitude, boost, boost_cautious, boost_really_cautious
END