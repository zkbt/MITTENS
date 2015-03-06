PRO plot_everything_radii, year=year, tel=tel, radius_range=radius_range
label=''
if keyword_set(year) then label += 'ye'+string(format='(I02)', year mod 100) + '_'
if keyword_set(tel) then label += 'te'+string(format='(I02)', tel) + '_'
if keyword_set(radius_range) then label += 'radius'+string(format='(I02)', 100*radius_range[0])+'to'+string(format='(I02)', 100*radius_range[1]) + '_'
	
	cleanplot, /silent
	f = subset_of_stars(year=year, tel=tel, radius_range=radius_range, suffix='medianed_lc.idl')

	n = n_elements(f);n = 30
 	radii = fltarr(n)
 	for i=0, n-1 do begin
 		star_dir = stregex(/extr, f[i], 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
 		lspm =  long(stregex(/extr, stregex(/extr, star_dir, 'ls[0-9]+'), '[0-9]+'))
 		info = get_lspm_info(lspm)
 		radii[i] = info.radius
 	endfor
 	f = f[sort(radii)]	
	set_plot, 'ps'
	device, filename=label + 'everything_radii.eps', /color, /encapsulated, xsize=5, ysize=n/4.0, /inches
	!x.margin =[6,2]
	!y.margin = [3,3]

	multiplot, /init, [3,n+1]
	for i=0, n-1 do begin

		star_dir = stregex(/extr, f[i], 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
		restore,  star_dir + '/target_lc.idl'
		if i eq 0 then xrange=[min(target_lc.hjd), max(target_lc.hjd)]
		xrange[0] = min(target_lc.hjd) < xrange[0]
		xrange[1] = max(target_lc.hjd) > xrange[1]
	endfor
	xrange[0] -= 20
	xrange[1] += 20
	print, xrange
	print, date_conv(xrange[0]+2400000.5d, 'S'), '      to           ', date_conv(xrange[1]+2400000.5d, 'S')
	yrange=[9,-9]
	@psym_circle
	n_colors= 8
	@constants
	loadct, 0
	multiplot
	plot, [0], title='Uncorrected', xs=5, ys=5, charsize=.5
	multiplot
	plot, [0], title='Stellar Variability', xs=5, ys=5, charsize=.5
	multiplot
	plot, [0], title='Residuals', xs=5, ys=5, charsize=.5

	loadct, /silent,   39
	for i=0, n-1 do begin

		star_dir = stregex(/extr, f[i], 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
		lspm =  long(stregex(/extr, stregex(/extr, star_dir, 'ls[0-9]+'), '[0-9]+'))
		info = get_lspm_info(lspm)
		sqrtf2rp = info.radius*109.04501

		restore, star_dir + '/field_info.idl'
		mearthk = string(format='(F3.1)', info_target.medflux - info_target.k_m)
		mag = string(format='(F4.1)', info_target.medflux)

		multiplot
		restore,  star_dir + '/target_lc.idl'
		lc = target_lc
		
		loadct, /silent,  0
		plot, lc.hjd, lc.flux*sqrtf2rp^2, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		oplot, [1,1]*max(xrange), [-4,4], noclip=1
		xyouts, min(xrange), 0, star_dir + '!C MEarth='+mag +'!C MEarth-K='+mearthk +'!C R=' + string(format='(F4.2)', info.radius), charsize=0.2, alignment=1.0

		loadct, /silent,  (i mod n_colors)*2+43, file='~/zkb_colors.tbl'

		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd,lc.flux*sqrtf2rp^2, psym=3,  color=color

		multiplot
		restore,star_dir + '/decorrelated_lc.idl'
		lc = decorrelated_lc
		loadct, /silent,  0
		plot, lc.hjd, lc.flux*sqrtf2rp^2, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		oplot, [1,1]*max(xrange), [-4,4], noclip=1
		loadct, /silent,  (i mod n_colors)*2+43, file='~/zkb_colors.tbl'

		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux*sqrtf2rp^2, psym=3,  color=color

		multiplot
		restore,   star_dir + '/medianed_lc.idl'
		lc = medianed_lc
		plot, lc.hjd, lc.flux*sqrtf2rp^2, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		loadct, /silent,  (i mod n_colors)*2+43, file='~/zkb_colors.tbl'

		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux*sqrtf2rp^2, psym=3,  color=color
	endfor
	multiplot, /def
	device, /close
	epstopdf, label + 'everything_radii'
END