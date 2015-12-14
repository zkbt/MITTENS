FUNCTION select_interesting_marples, boxes, mo 
                                ;This function receives a bunch of
                                ;candidate marples, spaced over time,
                                ;with different possible depths,
                                ;durations, and S/N, and collapses
                                ;them down to ones with S/N > 3, and
                                ;requires them to be
                                ;non-overlapping. If overlapping ones
                                ;are detected, then it selects the
                                ;highest signal to noise one in that
                                ;chunk. The S/N ratio cut off is
                                ;tunable, but sadly, only by
                                ;hard-codding it here because
                                ;I'm a moron and don't care about the
                                ;future person who is probably reading
                                ;this comment, trying to fix things or
                                ;understand things because something
                                ;is going wrong. Sorry future
                                ;person, don't care. 

  ;INITIAL VARIABLES
  signal_to_noise_threshold_to_give_a_shit_about = 3.0
     
  running_count_of_good_events = 0

                                ;initialize best arrays for each
                                ;timestamp

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

                                ;if have a tie for best S/N, then take
                                ;the shortest transit. This really
                                ;only happens when the S/N is super
                                ;low anyways. Plus the shorter
                                ;durations are more likely.

     IF n_elements(best_index) GT 1 THEN BEGIN
        best_index = best_index[0]
     ENDIF
                   
                                ;Store for later use
     best_hjds_jad[j] = boxes[j].hjd
     best_dur_jad[j] = boxes[j].duration[best_index]
     best_depth_jad[j] = boxes[j].depth[best_index]
     best_depth_sigma_jad[j] = boxes[j].depth_uncertainty[best_index]
     best_n_jad = boxes[j].N[best_index]
     best_rescaling_jad[j] = boxes[j].rescaling[best_index]
  ENDFOR

                                ;We now have, for this object and each
                                ;timestamp, the best candidate
                                ;event. We should now slaughter them
                                ;by the thousands to select only the
                                ;best ones.

                                ;Filter on S/N > 3
                                ;(WARNING: hard-coded above)
  signal_to_noises_of_everything = best_depth_jad / best_depth_sigma_jad
  good_ones = where(signal_to_noises_of_everything GT signal_to_noise_threshold_to_give_a_shit_about)
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
           iterated = 0
           IF culling_the_herd+current_look_ahead_value LT n_elements(best_hjds_jad) THEN BEGIN
              difference_from_next_event = best_hjds_jad[culling_the_herd+current_look_ahead_value] - best_hjds_jad[culling_the_herd]
              
                                ;EASY CASE: EVENTS ARE NOW MUTUALLY
                                ;EXCLUSIVE, NO MORE SEARCH SPACE
              IF difference_from_next_event GT best_dur_jad[culling_the_herd] AND difference_from_next_event GT best_dur_jad[culling_the_herd+current_look_ahead_value] THEN BEGIN
                 still_searching = 0
              ENDIF

                                ;PARTIAL OVERLAP OF EVENTS:
              IF difference_from_next_event LE best_dur_jad[culling_the_herd] OR difference_from_next_event LE best_dur_jad[culling_the_herd+current_look_ahead_value] THEN BEGIN
                                ;May the best one win
                 SN1 = best_depth_jad[culling_the_herd] / best_depth_sigma_jad[culling_the_herd]
                 SN2 = best_depth_jad[culling_the_herd+current_look_ahead_value] / best_depth_sigma_jad[culling_the_herd+current_look_ahead_value]
                           
                 IF SN1 GE SN2 THEN BEGIN
                                ;Kill event 2
                    best_depth_jad[culling_the_herd+current_look_ahead_value] = 0
                 ENDIF
                 IF SN2 GT SN1 THEN BEGIN
                                ;Kill event 1
                    best_depth_jad[culling_the_herd] = 0
                 ENDIF
                                ;Iterate the looking ahead value
                 current_look_ahead_value = current_look_ahead_value + 1
                 iterated = 1
                 still_searching = 1 ;just in case i fucked up and change it somewhere?
              ENDIF
              
           ENDIF ELSE BEGIN
                                ;No more array to search!
              still_searching = 0
           ENDELSE

           IF iterated EQ 0 THEN BEGIN
              current_look_ahead_value = current_look_ahead_value + 1
           ENDIF
        ENDWHILE
     ENDIF
  ENDFOR
               
                                ;NOW WE HAVE A FINISHED ENSEMBLE OF EVENTS
                                ;CULL THE HERD (we already set depths
                                ;to 0 for bad events)

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

                                ;Don't add things that have S/N
                                ;< 3 and good ones = -1 (because if
                                ;there are no good ones then we get -1
                                ;and -1 index is python-y because FUCK
                                ;IDL
  do_it = 1
  IF n_elements(good_ones) EQ 1 THEN BEGIN
     IF good_ones EQ -1 THEN BEGIN
        do_it = 0
     ENDIF
  ENDIF

  ensemble_of_boxes = replicate({hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0l, rescaling:0.0d, mo:''}, n_elements(good_ones))  

  If do_it EQ 1 THEN BEGIN
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].hjd = best_hjds_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].duration = best_dur_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].depth = best_depth_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].depth_uncertainty = best_depth_sigma_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].n = best_n_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].rescaling = best_rescaling_jad
     ensemble_of_boxes[running_count_of_good_events:running_count_of_good_events + n_elements(best_hjds_jad)-1].mo = mo
     
  ENDIF

  IF do_it EQ 0 THEN BEGIN
     ensemble_of_boxes = replicate({hjd:0.0d, duration:0.0d, depth:0.0d, depth_uncertainty:0.0d, n:0l, rescaling:0.0d, mo:''}, 1)
     ensemble_of_boxes = ensemble_of_boxes[0:0]
  ENDIF


  return,ensemble_of_boxes

END
