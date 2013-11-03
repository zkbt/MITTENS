PRO plot_everything, year=year, tel=tel, radius_range=radius_range
label=''
if keyword_set(year) then label += 'ye'+string(format='(I02)', year mod 100) + '_'
if keyword_set(tel) then label += 'te'+string(format='(I02)', tel) + '_'
if keyword_set(radius_range) then label += 'radius'+string(format='(I02)', 100*radius_range[0])+'to'+string(format='(I02)', 100*radius_range[1]) + '_'
	
	f = subset_of_stars(year=year, tel=tel, radius_range=radius_range, suffix='medianed_lc.idl')
;	f = star_dirs;f = file_search('stars/tel0*lspm*/medianed_lc.idl')
	n = n_elements(f);n = 30
	;n = 100
	multiplot, /init, [3,n]
	xrange = [55450, 55700]
	yrange=[0.04, -0.04]
	@psym_circle
	loadct, 39
	set_plot, 'ps'
	device, filename='everything_2011.eps', /color, /encapsulated, xsize=5, ysize=n/4.0, /inches
	loadct, 39
	for i=0, n-1 do begin

		star_dir = stregex(/extr, f[i], 'ls[0-9]+/ye[0-9]+/te[0-9]+/')

		multiplot
		restore, star_dir + '/target_lc.idl'
		lc = target_lc
		
		loadct, (i mod 8)*2+43, file='~/zkb_colors.tbl'
		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		xyouts, min(xrange), 0, star_dir, charsize=0.2
		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux, psym=3,  color=color

		multiplot
		restore, star_dir + '/decorrelated_lc.idl'
		lc = decorrelated_lc
		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux, psym=3,  color=color

		multiplot
		restore,  star_dir + '/medianed_lc.idl'
		lc = medianed_lc
		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux, psym=3,  color=color

	endfor
	multiplot, /def
	device, /close
	epstopdf, 'everything_2011'
END