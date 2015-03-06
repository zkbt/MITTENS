PRO plot_struct, s, tags=tags, xstyle=xstyle, ystyle=ystyle, legend=legend, xaxis=xaxis, xtickunits=xtickunits, psym=psym, ygap=ygap, symsize=symsize

	t = tag_names(s)
	n = n_tags(s)

	theta = findgen(21)/20*!pi*2
	usersym, cos(theta), sin(theta)

	if not keyword_set(tags) then tags = indgen(n)
	if not keyword_set(xaxis) then xaxis = lindgen(n_elements(s.(tags[0])))
	if not keyword_set(psym) then psym=-8
	if not keyword_set(symsize) then symsize=0.5
	if not keyword_set(xtickunits) then xtickunits=''
	interesting = bytarr(n_elements(tags))
	for i=0, n_elements(tags)-1 do if stddev(s.(tags[i])) gt 0 then interesting[i] = 1
	i = where(interesting, n_interesting)
	
	no_axes = 0
	if keyword_set(ystyle) then if (ystyle AND 4) gt 0 then no_axes = 1B

	if no_axes then begin
		old_margin = !x.margin[0]
		!x.margin[0] *= 2
	endif
	multiplot, [1,n_interesting], /init, ygap=ygap
	for j=0, n_interesting-1 do begin
		multiplot
		if j eq n_interesting-1 then xt=xtickunits else xt=''
		plot, xaxis, s.(tags[i[j]]), ytitle=t[tags[i[j]]],  psym=psym, /yno, symsize=symsize, xstyle=xstyle, ystyle=ystyle, xtickunits=xt
		if no_axes then xyouts, min(xaxis), 0, alignment=1.0, t[tags[i[j]]]+ '  ';legend, box=0, /top, /left, t[tags[i[j]]]
	endfor
	multiplot, /def
	if no_axes then !x.margin[0] = old_margin
END
