PRO load_summary_of_marples, all=all

	common mearth_tools
	threshold = 0.0
;	template = {ls:0l, ye:0l, te:0l, star_dir:'', hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0, rescaling:0.0f}
	f = file_search('mo*/combined/box_pdf.idl')
	mo = name2mo(f)
	restore, f[0]
	starting_size = 20000000l ;20 million
	ensemble_of_boxes = replicate({hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0l, rescaling:0.0d, mo:''}, starting_size)
	ensemble_of_mos = strarr(starting_size)
;	ensemble_of_star_dirs = strarr(starting_size)
	counter = 0
        
        ;Added by jason
        running_count_of_good_events = 0
        ;End Added by jason

	FOR i=0, n_elements(f)-1 DO BEGIN
           print,"on ",str(i)," of ",n_elements(f)
		
           ;Get all the boxes
           restore, f[i]

           ;Filter the events to non-overlapping, S/N > 3 events only
           filtered_events = select_interesting_marples(boxes,mo[i])
           n_for_this_star = n_elements(filtered_events.hjd)

           ;Stuff the events for this one star in our array

           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].hjd = filtered_events.hjd
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].duration = filtered_events.duration
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].depth = filtered_events.depth
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].depth_uncertainty = filtered_events.depth_uncertainty
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].n = filtered_events.n
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].rescaling = filtered_events.rescaling
           ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_for_this_star-1].mo = filtered_events.mo

           running_count_of_good_events += n_elements(n_for_this_star)

           ;Check for errors
           IF running_count_of_good_events GT starting_size THEN BEGIN
              mprint, error_string, 'the assumed starting size of ', rw(starting_size), " for the MarPLE array wasn't big enough!"
              stop
           ENDIF
        ENDFOR

        ;Trim the excess from 20 million to
        ;get the actual array of actual things
        ;for actual reasons
	ensemble_of_boxes = ensemble_of_boxes[0:running_count_of_good_events]

        ;Get rid of 0's in the array (when there are no marples?)
        good_filter = where(ensemble_of_boxes.hjd GT 0)
        ensemble_of_boxes = ensemble_of_boxes[good_filter]
        interesting_marples = ensemble_of_boxes

	save, interesting_marples, filename='population/summary_of_interesting_marples.idl'

END
