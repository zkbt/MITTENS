PRO loop_candidates
	c = load_candidates()
	c.chi = alog10(c.chi)
	interesting = c.fap lt 0.05
	xplot, 25, xsize=1000, ysize=1000
	plot_nd, c, dye=interesting
	c = c[where(interesting, n)]
	print_struct, c
	a = question("press enter to continue")
	for i=0, n-1 do begin
		set_star, c[i].lspm
		plot_star
	endfor
END