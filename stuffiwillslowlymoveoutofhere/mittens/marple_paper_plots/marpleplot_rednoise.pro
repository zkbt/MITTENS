PRO marpleplot_rednoise, r, eps=eps
;	if ~keyword_set(r) then 	r = load_rednoises()

	filename = 'marpleplot_rednoise.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=1.5, /inches, /color
	endif
	!p.charsize=0.6
	titles = ['2008-2009', '2009-2010', '2010-2011', '2011-2012']

	smultiplot, [4,1], /init, xgap=0.005
	years = [8,9,10,11]
	loadct, 39
	for y=0, n_elements(years)-1 do begin
		smultiplot
		r = load_rednoises(ye=years[y], n=100, te=te)
		if y eq 0 then ytitle='# of MEarth Target Stars' else ytitle=''
		if y eq 1 then xtitle='                                   Red Noise Fraction ('+ goodtex('r_{\sigma, r}')+')' else xtitle=''

		n = n_elements(r[0].redvar)
		colors = fix((findgen(n)+1)*254.0/n+0.01)
		for i=0, n_elements(r[0].redvar)-1 do begin
			plothist, r.redvar[i], bin=0.05, overplot=(i ne 0), thick=2, color=colors[i], xtitle=xtitle, title=titles[y], ytitle=ytitle, yr=[0,175], ys=1
		endfor

	endfor

	min_duration = 0.02
	max_duration = 0.1
	bin_duration = 0.01
	n_durations = (max_duration - min_duration)/bin_duration+1;10
	durations = findgen(n_durations)*bin_duration + min_duration

	al_legend, color=colors, linestyle=0, thick=2, string(durations*24, form='(F3.1)') + ' hr', box=0, /right, /top, charsize=0.5
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
	smultiplot, /def
	stop
END