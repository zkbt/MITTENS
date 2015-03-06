FUNCTION fit_rdisc,noerase=noerase, star, radii=radii, periods=periods, thick=thick
	n_radii = n_elements(radii)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90

	smultiplot, [2,2], /init, ygap=0.03
	smultiplot
	yr = [0.0, 1.0]
	xr = [0.5, 20]
	i_mode = where(tag_names(star) eq 'PHASED')
	loadct, 0
	plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0, /xlog
	loadct, 39
	for i=0, n_elements(radii)-1 do begin
		oplot, periods, star.(i_mode).period_detection[*,i]/star.(i_mode).period_transitprob, color=radii_color[i], thick=thick
	endfor
	oplot, periods, star.(i_mode).period_window, linestyle=1, color=0

	smultiplot
	i_mode = where(tag_names(star) eq 'TRIGGERED')
	loadct, 0
	plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0,/xlog
	loadct, 39
	for i=0, n_elements(radii)-1 do begin
		oplot, periods, star.(i_mode).period_detection[*,i]/star.(i_mode).period_transitprob, color=radii_color[i], thick=thick
	endfor
	oplot, periods, star.(i_mode).period_window, linestyle=1, color=0


	yr = [0.0001, 10.0]
	smultiplot
	i_mode = where(tag_names(star) eq 'PHASED')
	loadct, 0
	plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0, /xlog, /ylog
	loadct, 39
	for i=0, n_elements(radii)-1 do begin
		eta_disc = star.(i_mode).period_detection[*,i]/star.(i_mode).period_transitprob
		oplot, periods, eta_disc/(1-eta_disc) , color=radii_color[i], thick=thick
	endfor

	smultiplot
	i_mode = where(tag_names(star) eq 'TRIGGERED')
	loadct, 0
	plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0,/xlog, /ylog
	loadct, 39
	for i=0, n_elements(radii)-1 do begin
		eta_disc = star.(i_mode).period_detection[*,i]/star.(i_mode).period_transitprob
	oplot, periods, eta_disc/(1-eta_disc) , color=radii_color[i], thick=thick
	endfor



	smultiplot, /def
	return, 0
END