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

	for i=0, n_elements(f)-1 do begin
		
		restore, f[i]
	;	if n_elements(ensemble_of_boxes) eq 0 then ensemble_of_boxes = boxes else ensemble_of_boxes = [ensemble_of_boxes, boxes]
;		if n_elements(ensemble_of_mos) eq 0 then ensemble_of_mos = replicate(ls[i], n_elements(boxes)) else ensemble_of_mos = [ensemble_of_mos, replicate(ls[i], n_elements(boxes))]
		mprint, f[i]


                ;ADDED BY JASON DELETE IF IT TURNS OUT I'M A FUCK UP
                                ;for Each file (that we have loaded),
                                ;need to collapse based on duplicates
                                ;and S/N before 

                ;initialize best arrays for each timestamp
                n_timestamps = n_elements(boxes.hjd)
                
                best_hjds_jad = FLTARR(n_timestamps)
                best_dur_jad = FLTARR(n_timestamps)
                best_depth_jad = FLTARR(n_timestamps)
                best_depth_sigma_jad = FLTARR(n_timestamps)
                best_n_jad = FLTARR(n_timestamps)
                best_rescaling_jad = FLTARR(n_timestamps)

                ;Loop through all the timestamps for
                                ;this object and select the best
                                ;single candidate event from each
                                ;timestamp
                for j=0,n_elements(boxes.hjd)-1 do begin
                   max_signal_to_noise = max(boxes[j].depth / boxes[j].depth_uncertainty)
                   best_index = where(boxes[j].depth/boxes[j].depth_uncertainty EQ max_signal_to_noise)
                   
                   ;Store for later use
                   best_hjds_jad[j] = boxes[j].hjd
                   best_dur_jad[j] = boxes[j].duration[best_index]
                   best_depth_jad[j] = boxes[j].depth[best_index]
                   best_depth_sigma_jad[j] = boxes[j].depth_uncertainty[best_index]
                   best_n_jad = boxes[j].N[best_index]
                   best_rescaling_jad[j] = boxes[j].rescaling[best_index]
                endfor

               ;We now have, for this object and each
                                ;timestamp, the best candidate
                                ;event. We should now slaughter them
                                ;by the thousands to select only the
                                ;best ones.

                ;Filter on S/N > 3 (warning: hard-coded)
                signal_to_noises_of_everything = best_depth_jad / best_depth_sigma_jad
                good_ones = where(signal_to_noises_of_everything GT 3.0)
                best_hjds_jad = best_hjds_jad[good_ones]
                best_dur_jad = best_dur_jad[good_ones]
                best_depth_jad = best_depth_jad[good_ones]
                best_depth_sigma_jad = best_depth_sigma_jad[good_ones]
                best_n_jad = best_n_jad[good_ones]
                best_rescaling_jad = best_rescaling_jad[good_ones]

                ;Now need to eliminate duplicate overlapping events
                                ;This loops sets to 0 all over-lapping
                                ;marples that have a lower signal to
                                ;noise than the ones it overlaps with.
                for culling_the_herd=0,n_elements(best_hjds_jad)-1 do begin
                   if best_depth_jad[culling_the_herd] NE 0 then begin
                                ;the array is time ordered, so only
                                ;have to search so far
                      still_searching = 1
                      current_look_ahead_value = 1
                      WHILE still_searching EQ 1 DO BEGIN
                         IF culling_the_herd+current_look_ahead_value LE n_elements(best_hjds_jad) THEN BEGIN
                            difference_from_next_event = best_hjds_jad[culling_the_herd+current_look_ahead_value] - best_hjds_jad[culling_the_herd]
                            IF difference_from_next_event GT best_dur_jad[culling_the_herd] AND difference_from_next_event GT best_dur_jad[culling_the_heard+current_look_ahead_value] THEN BEGIN
                               ;Mutually exclusive events, we're done
                               still_searching = 0
                            ENDIF
                            IF difference_from_next_event LT best_dur_jad[culling_the_herd] AND difference_from_next_event LT best_dur_jad[culling_the_heard+current_look_ahead_value] THEN BEGIN
                                 ;Overlapping events, may the best one
                                 ;win
                               SN1 = best_depth_jad[culling_the_herd] / best_depth_sigma_jad[culling_the_herd]
                               SN2 = best_depth_jad[culling_the_herd+current_look_ahead_value] / best_depth_sigma_jad[culling_the_herd+current_look_ahead_value]
                               IF SN1 GT SN2 THEN BEGIN
                                  ;Kill event 2
                                  best_depth_jad[culling_the_herd+current_look_ahead_value] = 0
                               ENDIF
                               IF SN2 GT SN1 THEN BEGIN
                                  ;Kill event 1
                                  best_depth_jad[culling_the_herd] = 0
                               ENDIF
                               ;Iterate the looking ahead value
                               current_look_ahead_value = current_look_ahead_value + 1
                               still_searching = 1 ;just in case i fucked up and change it somewhere?
                            ENDIF
                         ENDIF ELSE BEGIN
                            ;No more array to search!
                            still_searching = 0
                         ENDELSE
                      ENDWHILE
                   ENDIF
                ENDFOR
               
                ;NOW WE HAVE A FINISHED ENSEMBLE OF EVENTS
                ;CULL THE HERD (we set depths to 0 for bad events)
                signal_to_noises_of_everything = best_depth_jad / best_depth_sigma_jad
                good_ones = where(signal_to_noises_of_everything GT 3.0)
                best_hjds_jad = best_hjds_jad[good_ones]
                best_dur_jad = best_dur_jad[good_ones]
                best_depth_jad = best_depth_jad[good_ones]
                best_depth_sigma_jad = best_depth_sigma_jad[good_ones]
                best_n_jad = best_n_jad[good_ones]
                best_rescaling_jad = best_rescaling_jad[good_ones]
                      
                ;Need to somehow create the
                ;"ensemble_of_boxes" structure                
                ;END ADDED BY JASON

                ensemble_of_boxes.hjd[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_hjds_jad
                ensemble_of_boxes.duration[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_dur_jad
                ensemble_of_boxes.depth[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_depth_jad
                ensemble_of_boxes.depth_uncertainty[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_depth_sigma_jad
                ensemble_of_boxes.n[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_n_jad
                ensemble_of_boxes.rescaling[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = best_rescaling_jad
                ensemble_of_boxes.mo[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1] = mo[i]

                running_count_of_good_events += n_elements(best_hjds_jad)

		if running_count_of_good_events gt starting_size then begin
			mprint, error_string, 'the assumed starting size of ', rw(starting_size), " for the MarPLE array wasn't big enough!"
			stop
		endif
             endfor


        ;Trim the excess from 20 million to
        ;get the actual array of actual things
        ;for actual reasons
	ensemble_of_boxes = ensemble_of_boxes[0:running_count_of_good_events]


        interesting_marples = ensemble_of_boxes


	save, interesting_marples, filename='population/summary_of_interesting_marples.idl'

END
