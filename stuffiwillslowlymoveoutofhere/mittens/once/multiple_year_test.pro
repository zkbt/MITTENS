FUNCTION multiple_year_test
	f = file_search('ls*/ye11/te*/medianed_lc.idl')
	 ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  	ls_string = 'ls'+string(format='(I04)', ls)
    	te_string = 'te' + string(format='(I02)', te)

  	phot_summary = {planet_1sigma:0.0, unfiltered_planet_1sigma:0.0, predicted_planet_1sigma:0.0,  rms:0.0, unfiltered_rms:0.0, predicted_rms:0.0, n_obs:0}
	cloud = replicate({lspm:0, stellar_radius:0.0, n_years:0, ye08:phot_summary, ye09:phot_summary, ye10:phot_summary, ye11:phot_summary}, n_elements(f))
	t = tag_names(cloud)


	for i=0, n_elements(f)-1 do begin
		g =  file_search(ls_string[i] + '/ye*/'+te_string[i]+'/medianed_lc.idl')
		n = n_elements(g)
		if n gt 0 then begin
			cloud[i].lspm = ls[i]
			lspm_info = get_lspm_info(ls[i])
			cloud[i].stellar_radius = lspm_info.radius
		;	print_struct, cloud[i]
			for j=0, n-1 do begin
				ye_string  = stregex(/ext, g[j], 'ye[0-9]+')
				star_dir = strmid(g[j], 0, strpos(f[i], 'medianed'))
				restore, star_dir + 'medianed_lc.idl'
				restore, star_dir + 'target_lc.idl'
				if n_elements(medianed_lc.flux) ge 10 then begin
					i_tag = where(strmatch(t, ye_string, /fold_case))
					cloud[i].(i_tag).unfiltered_rms = stddev(target_lc.flux)
					cloud[i].(i_tag).rms = stddev(medianed_lc.flux)
					cloud[i].(i_tag).predicted_rms = mean(target_lc.fluxerr)
					target_lc.flux *=	(lspm_info.radius*109.04501)^2
					target_lc.fluxerr *=	(lspm_info.radius*109.04501)^2
						
					medianed_lc.flux *=	(lspm_info.radius*109.04501)^2
					medianed_lc.fluxerr *=	(lspm_info.radius*109.04501)^2
					cloud[i].(i_tag).planet_1sigma = sqrt( stddev(medianed_lc.flux))
					cloud[i].(i_tag).unfiltered_planet_1sigma = sqrt(stddev(target_lc.flux))
					cloud[i].(i_tag).predicted_planet_1sigma = sqrt(mean(target_lc.fluxerr))

					cloud[i].(i_tag).n_obs = n_elements(target_lc.flux)
					cloud[i].n_years += 1
				endif
			;	print, '   ', t[i_tag], cloud[i].(i_tag)
			endfor
		endif
	endfor
	i_multi = where(cloud.n_years gt 1, n_multi)
	print, 'of the', n_elements(cloud), ' stars observed this year, ' ,n_multi, ' have been previously observed at least a little bit'
	cloud = cloud[where(cloud.n_years gt 1)]
	

	set_plot, 'ps'
	device, filename='multiyear_planet_sigma.eps', /encap, /color, /inches, xsize=10, ysize=7.5
	@psym_circle
loadct, 39
	!p.charsize=1
	nsigma=2.5
	yrange=[0, max(cloud.ye11.unfiltered_planet_1sigma*sqrt(nsigma))]
	multiplot, /init, [3,1], xgap=0.02
	multiplot
	plot,  yrange=yrange, cloud.stellar_radius, cloud.ye11.predicted_planet_1sigma*sqrt(nsigma), psym=8, /nodata,  ytitle=goodtex(string(format='(F3.1)', nsigma)+'\sigma Photometric Precision Per Binned Point (Earth radii)'), title='Predicted'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.predicted_planet_1sigma*sqrt(nsigma), psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.predicted_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, color=80, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.predicted_planet_1sigma*sqrt(nsigma), psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.predicted_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, color=160, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.predicted_planet_1sigma*sqrt(nsigma), psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.predicted_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, color=240, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.predicted_planet_1sigma*sqrt(nsigma), psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.predicted_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.predicted_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5

	legend, colors=[0,240,160,80], psym=[8,8,8,8], symsize=[2,1,1,1], ['this year', '2010-11', '2009-10', '2008-09'], box=0
	multiplot
	plot, yrange=yrange, cloud.stellar_radius, cloud.ye11.unfiltered_planet_1sigma*sqrt(nsigma), psym=8, /nodata, xtitle='Stellar Radius (solar radii)', title='Raw Photometry'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.unfiltered_planet_1sigma*sqrt(nsigma), psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.unfiltered_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, color=80, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.unfiltered_planet_1sigma*sqrt(nsigma), psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.unfiltered_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, color=160, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.unfiltered_planet_1sigma*sqrt(nsigma), psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.unfiltered_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, color=240, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.unfiltered_planet_1sigma*sqrt(nsigma), psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.unfiltered_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.unfiltered_planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5
	multiplot
	plot, yrange=yrange, cloud.stellar_radius, cloud.ye11.planet_1sigma*sqrt(nsigma), psym=8, /nodata, title='-(CM + nightly offsets)'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.planet_1sigma*sqrt(nsigma), psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, color=80, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.planet_1sigma*sqrt(nsigma), psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, color=160, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.planet_1sigma*sqrt(nsigma), psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, color=240, noclip=0
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.planet_1sigma*sqrt(nsigma), psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.planet_1sigma*sqrt(nsigma),'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5
	multiplot, /def
	device, /close
	epstopdf, 'multiyear_planet_sigma.eps'




	set_plot, 'ps'
	device, filename='multiyear_phot_rms.eps', /encap, /color, /inches, xsize=10, ysize=7.5
	@psym_circle
loadct, 39
	!p.charsize=1
	nsigma=2.5
	yrange=[0, 0.03]
	multiplot, /init, [3,1], xgap=0.02
	multiplot
	plot,  yrange=yrange, cloud.stellar_radius, cloud.ye11.predicted_rms, psym=8, /nodata,  ytitle='RMS of Binned Points (mag.)', title='Predicted'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.predicted_rms, psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.predicted_rms,'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, noclip=0, color=80
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.predicted_rms, psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.predicted_rms,'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, noclip=0, color=160
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.predicted_rms, psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.predicted_rms,'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, noclip=0, color=240
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.predicted_rms, psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.predicted_rms,'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.predicted_rms,'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5
	legend, colors=[0,240,160,80], psym=[8,8,8,8], symsize=[2,1,1,1], ['this year', '2010-11', '2009-10', '2008-09'], box=0
	multiplot
	plot, yrange=yrange, cloud.stellar_radius, cloud.ye11.unfiltered_rms, psym=8, /nodata, xtitle='Stellar Radius (solar radii)', title='Raw Photometry'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.unfiltered_rms, psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.unfiltered_rms,'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, noclip=0, color=80
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.unfiltered_rms, psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.unfiltered_rms,'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, noclip=0, color=160
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.unfiltered_rms, psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.unfiltered_rms,'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, noclip=0, color=240
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.unfiltered_rms, psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.unfiltered_rms,'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.unfiltered_rms,'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5
	multiplot
	plot, yrange=yrange, cloud.stellar_radius, cloud.ye11.rms, psym=8, /nodata, title='-(CM + nightly offsets)'
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye08.rms, psym=8, color=80
	xyouts, cloud.stellar_radius, cloud.ye08.rms,'!C!C' + strcompress(/remo,  cloud.ye08.n_obs), align=0.5, charsize=0.5, noclip=0, color=80
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye09.rms, psym=8, color=160
	xyouts, cloud.stellar_radius, cloud.ye09.rms,'!C!C' + strcompress(/remo,  cloud.ye09.n_obs), align=0.5, charsize=0.5, noclip=0, color=160
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye10.rms, psym=8, color=240
	xyouts, cloud.stellar_radius, cloud.ye10.rms,'!C!C' + strcompress(/remo,  cloud.ye10.n_obs), align=0.5, charsize=0.5, noclip=0, color=240
	oplot, min_value=0.00001,  cloud.stellar_radius, cloud.ye11.rms, psym=8, color=0, symsize=1
	xyouts, cloud.stellar_radius, cloud.ye11.rms,'!C!C' + strcompress(/remo,  cloud.ye11.n_obs), align=0.5, charsize=0.5, noclip=0
;	xyouts, cloud.stellar_radius, cloud.ye11.rms,'!C!C' + strcompress(/remo,  cloud.lspm), align=0.5, charsize=0.5
	multiplot, /def
	device, /close
	epstopdf, 'multiyear_phot_rms.eps'



	return, cloud
END