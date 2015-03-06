PRO marpleplot_cleanrms, eps=eps, n_sigma, te=te, oneyear=oneyear, poster=poster
	@planet_constants
	cleanplot
	if ~keyword_set(n_sigma) then n_sigma = 3

	filename = 'marpleplot_cleanrms.eps'
	if keyword_set(oneyear) then filename = 'oneyear_marpleplot_cleanrms.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		if keyword_set(oneyear) then device, filename=filename, /encap, xsize=2.25, ysize=2.5, /inches, /color else device, filename=filename, /encap, xsize=7.5, ysize=2.5, /inches, /color


	endif
	!p.charsize=0.6
	!p.charthick=1.5
	!x.thick = 1.5
	!y.thick=1.5
; 	if keyword_set(oneyear) then begin
; 		!x.thick=2
; 		!y.thick = 2
; 		!p.charthick=2
; 	endif
	if ~keyword_set(oneyear) then smultiplot, [4,1], /init, xgap=0.005 else smultiplot, [1,1], /init
	years = [8,9,10,11]
	titles = ['2008-2009', '2009-2010', '2010-2011', '2011-2012']
	if keyword_set(oneyear) then titles=replicate(' ', 4)

	loadct, 39
	if keyword_set(oneyear) then start = n_elements(years)-1 else start = 0
	for i=start, n_elements(years)-1 do begin
		smultiplot
		p = load_photometric_summaries(ye=years[i], n=100, te=te, /clean, /unknown)
		if i eq start then ytitle=goodtex(rw(n_sigma) + '\sigma Per-Point Photometric Uncertainty!CAfter Cleaning with MarPLE (Earth radii)') else ytitle=''
		if keyword_set(oneyear) then ytitle=goodtex(rw(n_sigma) + '\sigma Per-Point Photometric Uncertainty!CAfter Cleaning (Earth radii)') 
		if i eq 1 then xtitle='                                   Stellar Radius (Solar radii)' else xtitle=''
		if keyword_set(oneyear) then xtitle='Stellar Radius (Solar radii)'
		loadct, 0
		plot, [0], ytitle=ytitle, title=titles[i], /nodata, 	xr=[0.08, 0.34], yr=[1,7], xs=3, ys=3, xtitle=xtitle
;		rms_to_plot = [1, 10]
;		labels = ['0.1% RMS', '1% RMS']
		rms_to_plot = [2, 4, 6, 8, 10]
		labels = ['0.2% RMS', '0.4% RMS', '0.6% RMS', '0.8% RMS', '1% RMS']
		r = findgen(100)/200
		for j=0, n_elements(rms_to_plot)-1 do begin
			r_planet = r*sqrt(rms_to_plot[j]/1000.0)*r_sun/r_earth*sqrt(n_sigma)
			oplot, r, r_planet, linestyle=1
			x_pos = 0.3
			slope = (interpol(r_planet, r, x_pos) - interpol(r_planet, r, x_pos-0.01))/(0.01) *(!p.position[3] - !p.position[1])/(!p.position[2] - !p.position[0])*!d.y_size/!d.x_size*(0.34- 0.08)/(8-1)
			angle = atan(slope)*180/!pi

			xyouts, 0.3, interpol(r_planet, r, 0.3) + 0.1,  labels[j], charsize=0.3, orient=angle, charthick=1
		endfor


		loadct, file='~/zkb_colors.tbl', 58
		theta = findgen(17)/16*2*!pi
		usersym, cos(theta), sin(theta)
		oplot, psym=8, p.info.radius, p.predicted_planet_1sigma*sqrt(n_sigma), symsize=0.25, thick=2
		loadct, file='~/zkb_colors.tbl', 54
		usersym, cos(theta), sin(theta), /fill
		oplot, psym=8, p.info.radius, p.unfiltered_planet_1sigma*sqrt(n_sigma), symsize=0.25, color=100
		usersym, cos(theta), sin(theta)
		oplot, psym=8, p.info.radius, p.unfiltered_planet_1sigma*sqrt(n_sigma), symsize=0.25, thick=2


	endfor
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

END