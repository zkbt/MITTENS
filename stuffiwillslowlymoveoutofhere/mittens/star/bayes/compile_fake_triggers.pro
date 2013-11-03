FUNCTION compile_fake_triggers,  nstars=nstars, year=year, tel=tel, lspm=lspm, radius_range=radius_range, remake=remake, cloud=cloud, star_dirs=star_dirs, minnights=minnights

	common mearth_tools
; 	filename = 'triggering_warmups.eps'
; 	if keyword_set(eps) then begin
; 		set_plot, 'ps'
; 		device, filename=filename, /encap, xsize=7.5, ysize=3, /inches, /color
; 	endif
	cleanplot
	!p.charsize=0.6

	;if ~keyword_set(year) then year = 11
	loadct, 39
	droplet = {radius:0.0, b:0.0, t23:0.0, depth:0.0, depth_uncertainty:0.0, n_untriggered_sigma:0.0, n_sigma:0.0, n_nights:0, n_points:0, n_points_before:0, transit_hjd:0, rednoise:0.0, rescaling:0.0}
		star_dirs = subset_of_stars(fake_trigger_dir+ 'bundles_injected_and_recovered.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range)
	star_dirs = star_dirs[sort(randomn(seed, n_elements(star_dirs)))]
	if ~keyword_set(nstars) then nstars=100
;	star_dirs = star_dirs[0:nstars-1]
	cloud = {injected:replicate(droplet, nstars*50000), recovered:replicate(droplet, nstars*50000)}

	
		ls = long(stregex(/ext, stregex(/ext, star_dirs,  'ls[0-9]+'), '[0-9]+'))
		ye = long(stregex(/ext, stregex(/ext, star_dirs,  'ye[0-9]+'), '[0-9]+'))
		te = long(stregex(/ext, stregex(/ext, star_dirs,  'te[0-9]+'), '[0-9]+'))
	
		count = 0
		starcount = 0
		i = 0
		while (starcount lt nstars and i lt n_elements(star_dirs)) do begin
			
			restore, star_dirs[i] +fake_trigger_dir+ 'bundles_injected_and_recovered.idl'
			restore, star_dirs[i] +fake_trigger_dir+ 'injected_and_recovered.idl'
			i+=1
			if max(bundle_of_injected.n_nights) lt minnights then continue
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].radius = injected[bundle_of_injected.which_fake].radius
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].t23 = injected[bundle_of_injected.which_fake].t23
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].b = injected[bundle_of_injected.which_fake].b
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].depth = bundle_of_injected.depth
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].depth_uncertainty = bundle_of_injected.depth_uncertainty
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].n_untriggered_sigma = bundle_of_injected.n_untriggered_sigma
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].n_sigma = bundle_of_injected.n_sigma
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].n_nights = bundle_of_injected.n_nights
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].n_points = bundle_of_injected.n_points
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].n_points_before = bundle_of_injected.n_points_before
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].transit_hjd = bundle_of_injected.transit_hjd
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].rednoise = bundle_of_injected.rednoise
			cloud.injected[count:count+n_elements(bundle_of_injected)-1].rescaling = bundle_of_injected.rescaling

			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].radius = recovered[bundle_of_recovered.which_fake].radius
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].t23 = recovered[bundle_of_recovered.which_fake].t23
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].b = recovered[bundle_of_recovered.which_fake].b
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].depth = bundle_of_recovered.depth
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].depth_uncertainty = bundle_of_recovered.depth_uncertainty
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].n_untriggered_sigma = bundle_of_recovered.n_untriggered_sigma
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].n_sigma = bundle_of_recovered.n_sigma
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].n_nights = bundle_of_recovered.n_nights
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].n_points = bundle_of_recovered.n_points
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].n_points_before = bundle_of_recovered.n_points_before
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].transit_hjd = bundle_of_recovered.transit_hjd
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].rednoise = bundle_of_recovered.rednoise
			cloud.recovered[count:count+n_elements(bundle_of_recovered)-1].rescaling = bundle_of_recovered.rescaling

			starcount +=1 
			count += n_elements(bundle_of_recovered)
	
			print, i, starcount, count, ' ',star_dirs[i]
			if keyword_set(plot) then begin
				erase
				smultiplot, [1,n_elements(radii)], /init
				for j=0, n_elements(radii)-1 do begin
					smultiplot
					i_plot = where(injected[bundle_of_injected.which_fake].radius eq radii[j], n_radius)
					if n_radius eq 0 then continue
					plot_binned, bundle_of_recovered.n_nights, bundle_of_recovered.n_sigma/bundle_of_injected.n_sigma, psym=3, yr=[-1,2], n_bins=max(bundle_of_recovered.n_nights), xs=3, xr=[0, max(bundle_of_recovered.n_nights)]
				endfor
				smultiplot, /def
			endif
		endwhile
	return, cloud
END