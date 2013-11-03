PRO plot_ensemble
	;e = load_ensemble()


	blend = where(e.bflag)

	cleanplot
	loadct, 0

	xplot
	erase
	x = e.peak
	xtitle = 'Peak'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	loadct, 42, file='~/zkb_colors.tbl'
	plot_binned, x[blend], e[blend].flux, psym=3, /overplot
	xr = !x.crange
	smultiplot
	loadct, 0
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def

	blend = where(e.bflag)
	cleanplot
	loadct, 0
	xplot
	erase
	x = e.see
	xtitle = 'Seeing'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	loadct, 42, file='~/zkb_colors.tbl'
	plot_binned, x[blend], e[blend].flux, psym=3, /overplot
	xr = !x.crange
	smultiplot
	loadct, 0
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def





	blend = where(e.bflag)
	cleanplot
	loadct, 0
	xplot
	erase
	x = e.ellipticity
	xtitle = 'Ellipticity'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)', xr=[0, .3]
	loadct, 42, file='~/zkb_colors.tbl'
	plot_binned, x[blend], e[blend].flux, psym=3, /overplot, xr=[0, .3]
	xr = !x.crange
	smultiplot
	loadct, 0
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def










	erase
	x = e.extc
	xtitle='Extinction'
	smultiplot, rowhei=[3, 1], [1,2], /init, ygap=0.01
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)', xr=[-.25,0]
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def


	erase
	x = e.airmass
	xtitle='Airmass'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def




	erase
	x = e.right_xlc
	xtitle='Right XLC'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def


	erase
	x = e.right_ylc
	xtitle='Right yLC'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def





	erase
	x = e.left_xlc
	xtitle='left XLC'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def


	erase
	x = e.left_ylc
	xtitle='left yLC'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def




	erase
	x = e.off
	xtitle='offset'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def



	erase
	x = e.bflag + randomn(seed, n_elements(e))*0.01
	xtitle='bflag'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30],  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def





	erase
	x = e.rms
	xtitle='RMS'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30]*1,  ytitle='Flux (in Earth areas)', xr=[0, max(x)]
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def





	erase
	x = e.common_mode
	xtitle='common_mode'
	smultiplot, rowhei=[3, 1], [1,2], /init
	smultiplot
	plot_binned, x, e.flux, psym=3, yr=[-30,30]*1,  ytitle='Flux (in Earth areas)'
	xr = !x.crange
	smultiplot
	plothist, x, xr=xr, xtitle=xtitle, bin=(max(xr) - min(xr))/30, /ylog
	smultiplot, /def








END