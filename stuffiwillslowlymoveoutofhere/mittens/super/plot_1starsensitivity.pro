PRO plot_1starsensitivity, noerase=noerase, star, radii=radii, periods=periods, thick=thick

	n_radii = n_elements(radii)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90



	smultiplot, [1,2], /init, ygap=0.03
	smultiplot
	yr = [0.001,0.15]
	xr = [0.5, 20]
		i_mode = where(tag_names(star) eq 'PHASED')
		loadct, 0
		plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0, /ylog, /xlog
		loadct, 39
		for i=0, n_elements(radii)-1 do begin
			oplot, periods, star.(i_mode).period_detection[*,i], color=radii_color[i], thick=thick
		;	oploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], color=fix(i*254./n_elements(radii)), linestyle=0
		endfor
		oplot, periods, star.(i_mode).period_window*star.(i_mode).PERIOD_TRANSITPROB, linestyle=1, color=0

	smultiplot

		i_mode = where(tag_names(star) eq 'TRIGGERED')
		loadct, 0
		plot, [0], /nodata, xr=xr, yr=yr, ys=3, noerase=noerase, xstyle=3, color=0, /ylog, /xlog
		loadct, 39
		for i=0, n_elements(radii)-1 do begin
			oplot, periods, star.(i_mode).period_detection[*,i], color=radii_color[i], thick=thick
		;	oploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], color=fix(i*254./n_elements(radii)), linestyle=0
		endfor
		oplot, periods, star.(i_mode).period_window*star.(i_mode).PERIOD_TRANSITPROB, linestyle=1, color=0

	smultiplot, /def
END