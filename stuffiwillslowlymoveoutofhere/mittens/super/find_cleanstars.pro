PRO find_cleanstars
	restore, 'obs_summary.idl' 
	if file_test('flat_summaries.idl') eq 0 then begin
		flat = load_roughcleansummaries(ye=11)   
		save, flat, filename='flat_summaries.idl'
	endif else restore, 'flat_summaries.idl'
	if file_test('harmonic_summaries.idl') eq 0 then begin
		harmonic = load_roughcleansummaries(ye=11, /sin)   
		save, harmonic,  filename ='harmonic_summaries.idl'
	endif else restore, 'harmonic_summaries.idl'

	for i=0, n_elements(flat)-1 do begin
		i_obs = where(obs_summary.lspm eq flat[i].ls and obs_summary.year eq flat[i].ye and obs_summary.tel eq flat[i].te, n_obs)
		i_harm = 	where(harmonic.ls eq flat[i].ls and harmonic.ye eq flat[i].ye and harmonic.te eq flat[i].te, n_harm)
		if n_harm gt 0 and n_obs gt 0 then begin
			droplet = {obs:obs_summary[i_obs], flat:flat[i].rough, harmonic:harmonic[i_harm].rough}
			if n_elements(cloud) eq 0 then cloud = droplet else cloud = [cloud, droplet]
		endif
	endfor

	i_ast = where(cloud.obs.astonly, n_ast, complement=i_planet)
	astro = cloud[i_ast]
	planet = cloud[i_planet]
	xr=[0.5,5]
	bin=0.1
	i = where(astro.obs.n_goodpointings ge 10)
	set_plot, 'ps'
	!p.charsize=0.7
	device, filename='super_roughclean_rescalings.eps', /encap, xsize=6, ysize=4, /inches
	smultiplot, [2,2], /init, xgap=0.02, ygap =0.005
	smultiplot
	plothist, planet.flat.rescaling, xr=xr, bin=bin, /nan
	al_legend, box=0, /top, /right, 'Planet Cadence!Ctowards flat line'
	smultiplot, /doy
	plothist, astro[i].flat.rescaling, xr=xr, bin=bin, /nan
	al_legend, box=0, /top, /right, 'Astrometric Cadence!Ctowards flat line'

	smultiplot
	plothist, planet.harmonic.rescaling, xr=xr, bin=bin, /nan, xtitle='                                 Required Noise Rescaling'
	al_legend, box=0, /top, /right, 'Planet Cadence!Ctowards single harmonic'
	smultiplot, /doy
	plothist, astro[i].harmonic.rescaling, xr=xr, bin=bin, /nan
	al_legend, box=0, /top, /right, 'Astrometric Cadence!Ctowards single harmonic'

	smultiplot, /def
	device, /close
	epstopdf, 'super_roughclean_rescalings.eps'
	set_plot, 'x'
	xgap =0.01
	ygap =0.01
	loadct, 0
	!p.color=0
	i = where(astro.obs.n_goodpointings ge 10 and astro.harmonic.chisq/astro.harmonic.dof lt 20)
	filename = 'super_astrocadence_sin.eps'
	d = astro[i].harmonic
	plot_nd, {reducedchissq:d.chisq/d.dof, upjumps:d.n_4sig_outliers_up/float(d.n_points), downjumps:d.n_4sig_outliers_down/float(d.n_points), rescaling_probably_lt:d.rescaling + d.uncertainty_in_rescaling}, eps=filename, label = 'Astro, Harmonic', xgap=xgap, ygap=ygap
	epstopdf, filename

	!p.color=0

	i = where(astro.obs.n_goodpointings ge 10 and astro.flat.chisq/astro.flat.dof lt 20)
	filename = 'super_astrocadence_flat.eps'
	d = astro[i].flat
	plot_nd, {reducedchissq:d.chisq/d.dof, upjumps:d.n_4sig_outliers_up/float(d.n_points), downjumps:d.n_4sig_outliers_down/float(d.n_points), rescaling_probably_lt:d.rescaling + d.uncertainty_in_rescaling}, eps=filename, label = 'Astro, Flat', xgap=xgap, ygap=ygap
	epstopdf, filename

	!p.color=0

	i = where(planet.obs.n_goodpointings ge 10 and planet.harmonic.chisq/planet.harmonic.dof lt 20)
	filename = 'super_planetcadence_sin.eps'
	d = planet[i].harmonic
	plot_nd, {reducedchissq:d.chisq/d.dof, upjumps:d.n_4sig_outliers_up/float(d.n_points), downjumps:d.n_4sig_outliers_down/float(d.n_points), rescaling_probably_lt:d.rescaling + d.uncertainty_in_rescaling}, eps=filename, label = 'Planet, Harmonic', xgap=xgap, ygap=ygap
	epstopdf, filename

	!p.color=0

	i = where(planet.obs.n_goodpointings ge 10 and planet.flat.chisq/planet.flat.dof lt 20)
	filename = 'super_planetcadence_flat.eps'
	d = planet[i].flat
	plot_nd, {reducedchissq:d.chisq/d.dof, upjumps:d.n_4sig_outliers_up/float(d.n_points), downjumps:d.n_4sig_outliers_down/float(d.n_points), rescaling_probably_lt:d.rescaling + d.uncertainty_in_rescaling}, eps=filename, label = 'Planet, Flat', xgap=xgap, ygap=ygap
	epstopdf, filename

stop
END