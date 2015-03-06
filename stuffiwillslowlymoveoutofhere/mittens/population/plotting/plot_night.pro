PRO plot_night, night
	xrange=[night, night+0.5]
	f = file_search('stars/tel0*lspm*/medianed_lc.idl')
	n = n_elements(f);n = 30
	for i=0, n-1 do begin
		restore, f[i]
		h = histogram(bin=1, min=xrange[0], max=xrange[1], medianed_lc.hjd)
		if h[0] gt 10 then begin
			star_dir = stregex(/extr, f[i], 'tel[0-9]+lspm[0-9]+')
			if n_elements(stars) eq 0 then stars =  star_dir else stars = [star_dir, stars] 
			print, star_dir, h
		end
		
	endfor

	n = n_elements(stars)
	multiplot, /init, [1,n]
	yrange=[0.02, -0.02]
	@psym_circle
	loadct, 39
	set_plot, 'ps'
	device, filename='everything_2011.eps', /color, /encapsulated, xsize=5, ysize=n/4.0, /inches
	loadct, 39
	for i=0, n-1 do begin

		star_dir = stars[i]

		multiplot
		restore, 'stars/' + star_dir + '/target_lc.idl'
		lc = target_lc
		
		loadct, (i mod 8)*2+43, file='~/zkb_colors.tbl'
		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5

		weight =1.0/lc.fluxerr^2
		color = weight/max(weight)*255
		plots, lc.hjd, lc.flux, psym=8,  color=color

		loadct, 0
		xyouts, min(xrange), 0, star_dir, charsize=0.2

; 		multiplot
; 		restore, 'stars/' + star_dir + '/decorrelated_lc.idl'
; 		lc = decorrelated_lc
; 		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
; 		weight =1.0/lc.fluxerr^2
; 		color = weight/max(weight)*255
; 		plots, lc.hjd, lc.flux, psym=3,  color=color
; 
; 		multiplot
; 		restore,  'stars/' + star_dir + '/medianed_lc.idl'
; 		lc = medianed_lc
; 		plot, lc.hjd, lc.flux, xrange=xrange, ys=7, /nodata, yrange=yrange, xs=5
; 		weight =1.0/lc.fluxerr^2
; 		color = weight/max(weight)*255
; 		plots, lc.hjd, lc.flux, psym=3,  color=color

	endfor
	multiplot, /def
	device, /close
	epstopdf, 'everything_2011'
END