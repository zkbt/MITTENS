PRO test_box_sampling
	s = subset_of_stars('box_pdf.idl')
	x = findgen(500)
	xplot, /top
	plot, [0], xr=[0,500], yr=[-1,1]
	int = 1
	a = fltarr(n_elements(x), n_elements(s))
	!p.multi=[0,2,3]
	for i=0, n_elements(s)-1 do begin
		restore, s[i] + 'box_pdf.idl'
		a[*, i] = a_correlate(boxes.depth/boxes.depth_uncertainty, x)
		plot, x, a[*, i]
		j = where(boxes.depth[1] ne 0 and finite(boxes.depth_uncertainty[1]))

		for k=2, 6 do begin 
			plothist, boxes[j].depth[1] - boxes[j].depth[k], bin=0.0001, /ylog, yr=[.1, 10000]
			legend, string(n_elements(where(boxes[j].depth[1] eq boxes[j].depth[k]))/float(n_elements(boxes[j].depth[1]))*100, form='(I3)') + '%', box=0
		endfor
		if question(int=int, 'hmmm?') then stop
	endfor
	stop
	med = median(dim=2, a)
	mad = median(abs(a- med#ones(n_elements(s))), dim=2)
	ploterror, med, mad, psym=8
END