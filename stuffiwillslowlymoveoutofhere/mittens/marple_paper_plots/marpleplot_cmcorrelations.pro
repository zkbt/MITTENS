PRO marpleplot_cmcorrelations, eps=eps
	common mearth_tools

	if keyword_set(remake) or file_test('prep_for_cmcorrelations.idl') eq 0 then begin
		cm = load_common_mode()
		e = load_ensemble(ye=11)
		bin = min(cm[1:*].mjd_obs - cm[0:*].mjd_obs)
		s = {common_mode:0.0, skytemp:0.0, humidity:0.0, mjd_obs:0.0d, n:0}
		cloud = replicate(s, n_elements(cm))
		cloud.mjd_obs = cm.mjd_obs
		cloud.common_mode = cm.flux
		for i=0, n_elements(cloud)-1 do begin
			i_match = where(abs(e.mjd_obs - cm[i].mjd_obs) lt bin/2.0, n_match)
			cloud[i].n = n_match
			if n_match gt 0 then begin
				cloud[i].skytemp = mean(e[i_match].skytemp)
				cloud[i].humidity = mean(e[i_match].humidity)
			end
			counter, i, n_elements(cloud), 'rebinning'
		endfor	
		cloud = cloud[where(cloud.n gt 0)]
		save, filename='prep_for_cmcorrelations.idl'
	endif else restore, 'prep_for_cmcorrelations.idl'

	cleanplot
	filename = 'marpleplot_cmcorrelations.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=3.5, ysize=2.5, /inches, /color
	endif else xplot, xsize=2000, ysize=500
	!p.charsize=0.65
	!x.margin[0]=12
	!y.margin[0] = 5
	yr = median(cloud.common_mode) + [1,-1]*1.48*mad(cloud.common_mode)*4
	smultiplot, [2,1], /init, xgap=0.01
	smultiplot
	loadct, 0
	dye = cloud.mjd_obs - min(cloud.mjd_obs)
	dye = dye/max(dye)
	dye*= 254.0
	plot_binned, cloud.humidity, cloud.common_mode, /yno, psym=3, yr=yr, xr=[0, 85], ytitle='Binned "Common Mode" (mag.)', xtitle='Relative Humidity (%)', xs=3, ys=3, n_bins=20,/sem;, color=dye
	smultiplot
	plot_binned, cloud.skytemp, cloud.common_mode, /yno, psym=3, yr=yr, xr=[-65, -42], xtitle=goodtex('T_{Sky} -T_{Ambient} (degrees C)'), xs=3, ys=3, /sem, n_bins=20;, color=dye
	smultiplot, /def

	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

END