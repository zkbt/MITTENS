PRO load_summary_of_marples, all=all

	common mearth_tools
	threshold = 0.0
;	template = {ls:0l, ye:0l, te:0l, star_dir:'', hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0, rescaling:0.0f}
	f = file_search('mo*/combined/box_pdf.idl')
	mo = name2mo(f)
	restore, f[0]
	starting_size = 20000000l
	ensemble_of_boxes = replicate(boxes[0], starting_size)
	ensemble_of_mos = strarr(starting_size)
;	ensemble_of_star_dirs = strarr(starting_size)
	counter = 0

	for i=0, n_elements(f)-1 do begin
		
		restore, f[i]
	;	if n_elements(ensemble_of_boxes) eq 0 then ensemble_of_boxes = boxes else ensemble_of_boxes = [ensemble_of_boxes, boxes]
;		if n_elements(ensemble_of_mos) eq 0 then ensemble_of_mos = replicate(ls[i], n_elements(boxes)) else ensemble_of_mos = [ensemble_of_mos, replicate(ls[i], n_elements(boxes))]
		mprint, f[i]
		ensemble_of_boxes[counter:counter + n_elements(boxes)-1] = boxes		
		ensemble_of_mos[counter:counter + n_elements(boxes)-1] = mo[i]		
;		ensemble_of_star_dirs[counter:counter + n_elements(boxes)-1] = stregex(f[i],'^box_pdf.idl', /ext)		

		counter += n_elements(boxes)
	;	help, ensemble_of_boxes, ensemble_of_mos, counter
		if counter gt starting_size then begin
			mprint, error_string, 'the assumed starting size of ', rw(starting_size), " for the MarPLE array wasn't big enough!"
			stop
		endif
	endfor
	ensemble_of_boxes = ensemble_of_boxes[0:counter-1]
	ensemble_of_mos = ensemble_of_mos[0:counter-1]
;	save, filename='population/ensemble_of_marples.idl', ensemble_of_boxes, ensemble_of_mos
	
	i_interesting = where(ensemble_of_boxes.depth/ensemble_of_boxes.depth_uncertainty gt 3, n_interesting)
	if n_interesting eq 0 then stop
	ai = array_indices(ensemble_of_boxes.depth, i_interesting)
	
	ordered_indices = reform(ai[1,*])
	ordered_durations = reform(ai[0,*])

	
	interesting_marples = replicate({hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0l, rescaling:0.0d, mo:''}, n_interesting)
	interesting_marples.hjd = ensemble_of_boxes[ordered_indices].hjd
	durations = ensemble_of_boxes.duration
	interesting_marples.duration = durations[i_interesting]
	depths = ensemble_of_boxes.depth
	interesting_marples.depth = depths[i_interesting]	
	depth_uncertaintys = ensemble_of_boxes.depth_uncertainty
	interesting_marples.depth_uncertainty = depth_uncertaintys[i_interesting]
	ns = ensemble_of_boxes.n
	interesting_marples.n = ns[i_interesting]
	rescalings = ensemble_of_boxes.rescaling
	interesting_marples.rescaling = rescalings[i_interesting]
	interesting_marples.mo = ensemble_of_mos[ordered_indices]


	save, interesting_marples, filename='population/summary_of_interesting_marples.idl'

END