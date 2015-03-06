PRO plot_sensitivitysummary, noerase=noerase, thick=thick
	common this_star
	common mearth_tools

	n_radii = n_elements(radii)
  	radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  	radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90



	smultiplot, [1,2], /init, ygap=0.03
	smultiplot
	estimate_sensitivity, 5, remake=remake, /trigger, sensitivity_filename=sensitivity_filename
	restore, sensitivity_filename
		loadct, 0
		plot, [0], /nodata, xr=[0,20], yr=[0,1], ys=3, noerase=noerase, ytitle=goodtex('Sensitivity assuming!C5\sigma in Triggered Single Events'), xstyle=3, color=0
		loadct, 39
		for i=0, n_elements(radii)-1 do begin
			oplot, periods, sensitivity[*,i], color=radii_color[i], thick=thick
		;	oploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], color=fix(i*254./n_elements(radii)), linestyle=0
		endfor
		oplot, periods, median(wfunction, dim=2), linestyle=1, color=0

	smultiplot
	estimate_sensitivity, 8, remake=remake, sensitivity_filename=sensitivity_filename
	restore, sensitivity_filename
		loadct, 0
		plot, [0], /nodata, xr=[0,20], yr=[0,1], ys=3, noerase=noerase, ytitle=goodtex('Sensitivity assuming!C8\sigma in Phased Search'), xstyle=3, color=0
		loadct, 39

		for i=0, n_elements(radii)-1 do begin
			oplot, periods, sensitivity[*,i], color=radii_color[i], thick=thick
		;	oploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], color=fix(i*254./n_elements(radii)), linestyle=0
		endfor
		oplot, periods, median(wfunction, dim=2), linestyle=1, color=0

	smultiplot, /def
END