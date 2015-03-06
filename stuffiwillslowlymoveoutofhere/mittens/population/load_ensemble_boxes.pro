FUNCTION load_ensemble_boxes, prior_cloud, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n

	
	subset = subset_of_stars('box_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n) + 'box_pdf.idl'
	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $

	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	subset = subset[sort(ye)]
	ls = long(stregex(/ext, stregex(/ext, subset, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, subset, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(subset)
	restore, subset[0]
	
	template = create_struct('LSPM', 0, 'STAR_DIR', '', boxes[0])
	tags = ['COMMON_MODE', 'AIRMASS', 'SEE', 'SKY', 'ELLIPTICITY', 'UNCERTAINTY_RESCALING']

	for i=0, n-1 do begin
		restore, subset[i]
		this = replicate(template, n_elements(boxes))
		copy_struct, boxes, this
		this.lspm = ls[i]
		this.star_dir = stregex(subset[i], /ext, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
		if n_elements(big_boxes) eq 0 then big_boxes = this else big_boxes = [big_boxes, this]
		print, subset[i]
;		erase
;		smultiplot, [2,n_elements(boxes[0].depth)], /init, colw=[1, .5]
		for j=0, n_elements(boxes[0].depth)-1 do begin
;			smultiplot
			m = where(boxes.n[j] gt 1, n_nonzero)
			if n_nonzero gt 1 then begin
				if stddev(boxes[m].rescaling[j]) gt 0 then begin
;					plothist, boxes[m].rescaling[j], bin=0.1, xout, yout, xs=3, xr=[0.5, max(boxes.rescaling)]
					k = where(strmatch(spliced_clipped_season_fit.name, 'UNCERTAINTY_RESCALING'), n_match)
					resc = spliced_clipped_season_fit[k].coef
					err = spliced_clipped_season_fit[k].uncertainty
;					plots, resc + [-err, err], [max(yout), max(yout)]/2., thick=3
;					plots, resc , max(yout)/2., psym=8, symsize=3
				endif
			endif
;			smultiplot
			if n_nonzero gt 1 then begin
;				plot_binned, boxes[m].rescaling[j], boxes[m].depth[j]/boxes[m].depth_uncertainty[j], psym=3, xr=[0.5, max(boxes.rescaling)] 
			endif
		endfor
;		smultiplot, /def
		if question('hmm?', int=int) then stop

	endfor
	return, big_boxes
END