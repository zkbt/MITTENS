PRO upgrade_mearth, remake=remake,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n
	
year = 11

	; find the stars that have low red-noise_cloud + low rescaling factor
	noise_summary_filename = 'noise_cloud_summary.idl'
	if keyword_set(remake) or file_test(noise_summary_filename) eq 0 then begin

		rednoise = load_rednoises(year=year, tel=tel, lspm=lspm, radius_range=radius_range);, n=500)
		photosummary = load_photometric_summaries(year=year, tel=tel, lspm=lspm, radius_range=radius_range);, n=500)
		noise_cloud = replicate(create_struct(photosummary[0], 'rednoise', 0.0, 'stellar_radius', 0.0), n_elements(photosummary))
		copy_struct, photosummary, noise_cloud
		for i=0, n_elements(noise_cloud)-1 do begin
			match = where(rednoise.info.n eq noise_cloud[i].lspm, n_match)
			if n_match eq 1 then noise_cloud[i].rednoise = sqrt(mean(rednoise[match].redvar)) else redvar = 0.0/0.0
		endfor
		save, filename=noise_summary_filename, noise_cloud
		i = where(noise_cloud.lspm gt 0 and noise_cloud.predicted_planet_1sigma gt 0 and noise_cloud.unfiltered_rms gt 0)
		noise_cloud = noise_cloud[i]		
		noise_cloud.stellar_radius = noise_cloud.info.radius
	endif else restore, noise_summary_filename
	
	; plot some summaries of these to make sure they're not a weird biased sample
	
	loadct, 39
;	xplot, xsize=1000, ysize=1000, 0, title='MEarth Targets Dyed by RMS/(predicted RMS)'
;	plot_nd, noise_cloud, tags=[0,1,2,3,5,6,7,8], dye=alog10(noise_cloud.rms/noise_cloud.predicted_rms >1), symsize=2

;	xplot, xsize=1000, ysize=1000, 1, title='MEarth Targets Dyed by Rednoise'
;	plot_nd, noise_cloud, tags=[0,1,2,3,5,6,7,8], dye=noise_cloud.rednoise, symsize=2

	cleanplot
	xplot, xsize=1000, ysize=1000, 2, title='Selected "Polite" Stars'
	polite = noise_cloud.rms/noise_cloud.predicted_rms lt 1.3 and noise_cloud.rednoise lt 0.1
	i_polite = where(polite, n_polite)
	plot_nd, noise_cloud, tags=[0,1,2,3,5,6,7,8], dye=polite, symsize=2


	n_panels = 4
	total_width =290
	width = total_width/n_panels
	left_side = 12
	panels = [[left_side + indgen(n_panels)*width],[ total_width - width*indgen(n_panels) - width]]
stop


	; calculate the detection efficiency we achieved with them in a season
	star_dirs = strarr(n_polite)
	for i=0, n_polite-1 do begin
		star_dirs[i] = make_star_dir(noise_cloud[i_polite[i]].lspm, 11)
		printl
		print,star_dirs[i]
		print_struct, noise_cloud[i_polite[i]]
	
		set_star, noise_cloud[i_polite[i]].lspm, 11
		xplot, xsize=1700, ysize=400, 4, title='Example Star = ' + star_dir()

		explore_pdf, 10, /hide
;		restore, star_dir() + 'cleaned_lc.idl'
		lc_plot, /time, /externalform, ymargin=!y.margin, xmargin = panels[0,*],  charsize=1, symsize=0.7,   replace='Linear in Time'
		!x.margin =  panels[1,*]
		plot_sensitivitysummary
	
		cleanplot
		!x.margin =  panels[2,*]
		smultiplot, [1,3], /init, ygap=0.02
		smultiplot, /dox
		plothist, noise_cloud.info.radius, ystyle=4, xr=[0.05, 0.4], bin=0.01, xs=5
		axis, xaxis=0,  xs=1, color=0
		vline, noise_cloud[i_polite[i]].info.radius, linestyle=2, color=0, thick=3
		al_legend, 'Stellar Radius', box=0, /right

		x = noise_cloud.rednoise
		smultiplot, /dox
		plothist, x, ystyle=4, xr=[0,1], bin=0.05, xs=5
		axis, xaxis=0,  xs=1, color=0
		vline, x[i_polite[i]], linestyle=2, color=0, thick=3
		al_legend, 'Red Noise', box=0, /right

		x = noise_cloud.rms/noise_cloud.predicted_rms
		smultiplot, /dox
		plothist, x, ystyle=4, bin=0.1, xs=5
		axis, xaxis=0,  xs=1, color=0
		vline, x[i_polite[i]], linestyle=2, color=0, thick=3
		al_legend, 'Acheived/Predicted RMS', box=0, /right


	
		smultiplot, /def
		if question(/int, rw(i)) then stop

	endfor

	stop
; 	cleanplot
; 	xplot, xsize=700, ysize=1000, 3, title='Sensitivity'
; 	s = compile_sensitivity(star_dirs=star_dirs, 3)
; 	al_legend, /top, /right, box=0, rw(n_polite) + ' stars'
; 	stop
; 	; scale it by an increased number of photons (number of telescopes!)

	; take as many of these as can be fit into a night as possible (penalize for extra photons)

	; calculate survey sensitivity

	; calculate expected yield given courtney's kepler results

END

