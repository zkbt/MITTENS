PRO plot_ensemble, c

	!p.multi=[0,8,4]
	tags = tag_names(c)
	for i=0, n_tags(c)-1 do begin
		plot, c.(i), c.flux, psym=3, xtitle=tags[i];, yrange=[100,-100]
	endfor
END