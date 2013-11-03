PRO backtrack_candidates
	c = load_candidates()
	i_interesting = where(c.fap lt 0.1, n)
	c = c[i_interesting]
	print_struct, c
;	c = c[uniq(c.lspm, sort(c.lspm))]
	h = histogram(c.lspm, reverse_indices=ri)
	i_interesting = where(h gt 1, n)
	c = c[ri[ri[i_interesting]]]
printl
	print_struct, c
	for i=0, n-1 do begin
		if c[i].lspm ne 1186 then begin
			update_star, c[i].lspm, /comb
			plot_star
		endif
	endfor
END