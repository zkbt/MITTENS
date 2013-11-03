PRO fit_eit
	e = load_eit()
	print, n_elements(e), ' available EIT estimates!'
; 	x = e.n_data
; 	y = e.n_eit
; 	lf = linfit(alog(x), alog(y))
; 	plot, x, y, psym=1,/xlog, /ylog, /iso
; 
; 	model = exp(lf[0] + lf[1]*alog(x))
; 	oplot, x, model
; 	
; 	print, stddev(alog(e.n_eit/model))


;	indep = transpose(alog([[e.n_data]]))
;	r = regress(indep, alog(e.n_eit), const=const)
;	model = exp(const + r#indep)
;	plot, model, e.n_eit, /xlog, /ylog, psym=1, /iso, title=stddev(alog(e.n_eit/model))
;	oplot,  [min(model), max(model)], [min(model), max(model)]

	indep = transpose(alog([[e.n_data], [e.n_periods]]))
	r = regress(indep, alog(e.n_eit), const=const)
	model = exp(const + r#indep)
	plot, model, e.n_eit, /xlog, /ylog, psym=1, /iso, title=stddev(alog10(e.n_eit/model)), /nodata
	xyouts, model, e.n_eit, e.lspm
	oplot, [min(model), max(model)], [min(model), max(model)]

	eit_coef = {const:const, n_data:r[0], n_periods:r[1]}
	save, eit_coef, filename='eit_coef.idl'


END