PRO marpleplot_candidates, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, eps=eps, poster=poster
	common mearth_tools
	filename = 'marpleplot_candidates.eps'
	if keyword_set(poster) then filename = 'poster_candidates.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		if ~keyword_set(poster) then device, filename=filename, /encap, xsize=7.5, ysize=3, /inches, /color else  device, filename=filename, /encap, xsize=6, ysize=3.5, /inches, /color
	endif
	cleanplot
	!p.charsize=1
	titles = '!D'+['2008-2009', '2009-2010', '2010-2011', '2011-2012']

	if keyword_set(poster) then begin
		!p.thick = 2
		!x.thick = 2
		!y.thick=!x.thick
		!p.charthick=2
	endif
	smultiplot, [4,1], /init, xgap=0.005
	years = [8,9,10,11]
	loadct, 39
	xrange=[0.5, 50]
	for y=0, n_elements(years)-1 do begin
		smultiplot
		c = load_pdf_candidates(year=years[y], tel=tel, lspm=lspm, radius_range=radius_range, n=30, /unknown)
	;	if keyword_set(show_all) then i_ok = indgen(n_elements(c)) else	
		if y eq 0 then i_ok = where(c.ignore eq 0 and c.known eq 0 and c.variability eq 0 and c.lspm ne 1085) else i_ok = where(c.ignore eq 0 and c.known eq 0 and c.variability eq 0)
		c = c[i_ok]
		c = c[sort(c.stats.boxes[n_elements(c[0].stats.boxes)-1])]

		if y eq 0 then ytitle=goodtex('D/\sigma') else ytitle=''
		if y eq 1 then xtitle='                         Candidate Period (days)' else xtitle=''
		loadct, 0
		plot, c.period, c.depth/c.depth_uncertainty, psym=1, /xlog, xs=3,  ys=3, /nodata, title=titles[y], xtitle=xtitle, ytitle=ytitle, xrange=xrange, yrange=[0,9]
		maxn =7000
		
		colors = (c.stats.boxes[n_elements(c[0].stats.boxes)-1]*255./maxn) < 255.0

; ;		maxn =10000
;		minn = 500
;		logn = alog10(c.stats.boxes[n_elements(c[0].stats.boxes)-1])
;		colors = (((logn - alog10(minn))*255./(alog10(maxn) - alog10(minn))) < 255.0) > 0


		theta = findgen(17)/16*2*!pi
		symsize=0.5
		loadct, 59, file='~/zkb_colors.tbl'
		usersym, cos(theta), sin(theta), /fill
		plots, c.period, c.depth/c.depth_uncertainty, noclip=0, color=colors, psym=8, symsize=symsize
		loadct, 0
		usersym, cos(theta), sin(theta), thick=1.5
		plots, c.period, c.depth/c.depth_uncertainty, noclip=0, color=0, psym=8, symsize=symsize

		if years[y] eq 8 then begin
			detected_periods = [1.58, 2.88]
			detected_sn = [8.2, 8.4]
			detected_names = ['GJ1214b     ', '          NLTT41135B']
			; GJ1214
			loadct, file='~/zkb_colors.tbl', 54
			usersym, cos(theta), sin(theta), /fill
			plots, detected_periods, detected_sn, psym=8, symsize=1.5*symsize, color=0
			loadct, file='~/zkb_colors.tbl', 42
			usersym, cos(theta), sin(theta), thick=2
			plots, detected_periods, detected_sn, psym=8, symsize=1.5*symsize, color=0
			loadct, 0
			xyouts, align=0.5, detected_periods, detected_sn-0.1, '!C' + detected_names, charthick=2, charsize=0.5
		endif
		if years[y] eq 9 then begin

			loadct, file='~/zkb_colors.tbl', 42
			arrow, 41, 8, 41, 9, /data, color=0, hthick=5,  hsize=-0.3
			loadct, file='~/zkb_colors.tbl', 54
			arrow, 41, 8, 41, 9, /solid, /data, color=0, thick=3, hsize=-0.3, hthick=0.1

			loadct, 0
			xyouts, align=0.9, 41, 8, '!CLSPM J1112+7626', charthick=2, charsize=0.5
		endif
	endfor
	
	n_points =[100, 200, 400, 800, 1600]
	loadct, 59, file='~/zkb_colors.tbl'
	usersym, cos(theta), sin(theta), /fill


	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
END