PRO marpleplot_rednoisemean, r, eps=eps
;	if ~keyword_set(r) then 	r = load_rednoises()

	filename = 'marpleplot_rednoise.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=3.75, ysize=2.5, /inches, /color
	endif
	!p.charsize=1.2

	titles = ['2008-2009', '2009-2010', '2010-2011', '2011-2012']
	colors = intarr(4)
	
	years = [8,9,10,11]
	loadct, 39
	for y=0, n_elements(years)-1 do begin
		r = load_rednoises(ye=years[y], n=100, te=te)
		if y eq 0 then ytitle='# of MEarth Target Stars' else ytitle=''
		if y eq 0 then xtitle='Red Noise Fraction ('+ goodtex('r_{\sigma, r}')+')' else xtitle=''

		n = n_elements(years)

		means = fltarr(n_elements(r.redvar[0]))
		for i=0, n_elements(r.redvar[0])-1 do begin
			means[i] = mean(r[i].redvar)
		endfor
		if y eq 0 then plothist, means, bin=0.05, /nodata, xtitle=xtitle, ytitle=ytitle, yr=[0,175], xr=[0,1], xs=3, ys=1
		plothist, /over, means, bin=0.05, color=colors[y], thick=2, linestyle=y

	endfor

	al_legend, color=colors, thick=2, titles, box=0, /right, /top, charsize=0.8, linestyle=indgen(4)

	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
END