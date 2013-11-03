PRO plot_night_radii, night, year=year, tel=tel, radius_range=radius_range
label=''
if keyword_set(year) then label += 'ye'+string(format='(I02)', year mod 100) + '_'
if keyword_set(tel) then label += 'te'+string(format='(I02)', tel) + '_'
if keyword_set(radius_range) then label += 'radius'+string(format='(I02)', 100*radius_range[0])+'to'+string(format='(I02)', 100*radius_range[1]) + '_'
	
	f = subset_of_stars(year=year, tel=tel, radius_range=radius_range, suffix='medianed_lc.idl')
	xrange=[night+.1, night+0.5]
	yrange=[0.02, -0.02]*1.5
	n_colors= 8
	caldat, 2400000l + night, m, d, y
	str = strcompress(/remo, y) + '-' + strcompress(/remo, m) + '-' + strcompress(/remo, d)
;	f = file_search('stars/tel0*lspm*/medianed_lc.idl')
	n = n_elements(f);n = 30
	set_plot, 'ps'
	filename = 'night_'+strcompress(/remo, night)
	device, filename=filename+'.eps', /color, /encapsulated, xsize=10, ysize=3, /inches
	loadct, 3
	@make_plots_thick
	!p.charsize=1
	plot,[0], xrange=24*(xrange-night), ys=3, /nodata, yrange=yrange, xs=3, xtitle='Time During Night (hours)', ytitle='Relative Flux (mag.)'
	for i=0, n-1 do begin
		restore, f[i]
		h = histogram(bin=1, min=xrange[0], max=xrange[1], medianed_lc.hjd, reverse_indices=ri)
		if h[0] gt 1 then begin
		star_dir = stregex(/extr, f[i], 'ls[0-9]+/ye[0-9]+/te[0-9]+/')



		lspm =  long(stregex(/extr, stregex(/extr, star_dir, 'ls[0-9]+'), '[0-9]+'))
		info = get_lspm_info(lspm)
		sqrtf2rp = info.radius*109.04501
		if info.radius lt 0.4 then begin
		restore, star_dir + '/field_info.idl'
		mearthk = string(format='(F3.1)', info_target.medflux - info_target.k_m)
		mag = string(format='(F4.1)', info_target.medflux)

		

		restore,  star_dir + '/decorrelated_lc.idl'
; or stddev(decorrelated_lc.flux) gt 0.02
	;		if stddev(decorrelated_lc.flux) gt 10*mean(decorrelated_lc.fluxerr) 
			if stddev(decorrelated_lc.flux) gt 0.02 then print, 'BLERG!' else begin

				restore, star_dir + '/target_lc.idl'
				lc = target_lc[ri[ri[0]:ri[1]-1]]
				lc.flux -= median(lc.flux)
							restore,  star_dir + '/ext_var.idl'
				ext_var = ext_var[ri[ri[0]:ri[1]-1]]
				lc.hjd = ext_var.mjd_obs
				lc.hjd -= night
				lc.hjd *=24

		
		
				loadct, /silent,  0
			;	xyouts, min(xrange), 0, star_dir + '!C MEarth='+mag +'!C MEarth-K='+mearthk +'!C R=' + string(format='(F4.2)', info.radius), charsize=0.2, alignment=1.0
		
			;	loadct, /silent,  (i mod n_colors)*2+43, file='~/zkb_colors.tbl'
		loadct, /silent,  42, file='~/zkb_colors.tbl'
				weight =1.0/lc.fluxerr^2
				color =(info.radius)/.35*255;weight/max(weight)*255
				plots, lc.hjd,lc.flux, psym=8, symsize=0.5 , color=color, noclip=0
				oplot, lc.hjd,lc.flux, symsize=0.5 , color=color, noclip=0, linestyle=0
					if n_elements(stars) eq 0 then stars =  star_dir else stars = [star_dir, stars] 
			print, star_dir, h


	
			endelse
			endif



		endif
		
	endfor

	restore, 'cm.idl'
	loadct, 0
			h = histogram(bin=1, min=xrange[0], max=xrange[1],cm.mjd_obs, reverse_indices=ri)
	cm = cm[ri[ri[0]:ri[1]-1]]
	oplot, (cm.mjd_obs-night)*24, cm.flux- median(cm.flux), psym=-8, thick=5
	n = n_elements(stars)
	
	xyouts, (xrange[0] - night)*24, 0.028, strcompress(n) + ' M dwarfs on '+str
		

	device, /close
	epstopdf, filename






	radii = fltarr(n)
	for i=0, n-1 do begin
		star_dir = stars[i]
		lspm =  long(stregex(/extr, stregex(/extr, star_dir, 'ls[0-9]+'), '[0-9]+'))
		info = get_lspm_info(lspm)
		radii[i] = info.radius
	endfor
	stars = stars[sort(radii)]

; 
; 
; 	multiplot, /init, [1,n]
; 
; 	@psym_circle
; 	loadct, 39
; 	set_plot, 'ps'
; 	device, filename='everything_2011.eps', /color, /encapsulated, xsize=5, ysize=n/4.0, /inches
; 	loadct, 39
; 	for i=0, n-1 do begin
; 
; 		star_dir = stars[i]
; 	lspm =  long(stregex(/extr, stregex(/extr, star_dir, 'lspm[0-9]+'), '[0-9]+'))
; 		info = get_lspm_info(lspm)
; 		sqrtf2rp = info.radius*109.04501
; 
; 		restore, 'stars/' + star_dir + '/field_info.idl'
; 		mearthk = string(format='(F3.1)', info_target.medflux - info_target.k_m)
; 		mag = string(format='(F4.1)', info_target.medflux)
; 		multiplot
; 		restore, 'stars/' + star_dir + '/target_lc.idl'
; 		lc = target_lc
; 	
; 
; 
; 		loadct, /silent,  0
; 		plot, lc.hjd, lc.flux*sqrtf2rp^2, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
; 		oplot, [1,1]*max(xrange), [-4,4], noclip=1
; 		xyouts, min(xrange), 0, star_dir + '!C MEarth='+mag +'!C MEarth-K='+mearthk +'!C R=' + string(format='(F4.2)', info.radius), charsize=0.2, alignment=1.0
; 
; 		loadct, /silent,  (i mod n_colors)*2+43, file='~/zkb_colors.tbl'
; 
; 		weight =1.0/lc.fluxerr^2
; 		color = weight/max(weight)*255
; 		plots, lc.hjd,lc.flux*sqrtf2rp^2, psym=8, symsize=0.5 , color=color
; 
; 
; ; 		multiplot
; ; 		restore, 'stars/' + star_dir + '/decorrelated_lc.idl'
; ; 		lc = decorrelated_lc
; ; 		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
; ; 		weight =1.0/lc.fluxerr^2
; ; 		color = weight/max(weight)*255
; ; 		plots, lc.hjd, lc.flux, psym=3,  color=color
; ; 
; ; 		multiplot
; ; 		restore,  'stars/' + star_dir + '/medianed_lc.idl'
; ; 		lc = medianed_lc
; ; 		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
; ; 		weight =1.0/lc.fluxerr^2
; ; 		color = weight/max(weight)*255
; ; 		plots, lc.hjd, lc.flux, psym=3,  color=color
; 
; 	endfor
; 	multiplot, /def
; 	device, /close
; 	epstopdf, 'everything_2011'




END