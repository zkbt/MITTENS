PRO lc_events, candidate, eps=eps, diagnosis=diagnosis, comparisons=comparisons, transit_number=transit_number, sin_params=sin_params
	common this_star
 	if not keyword_set(candidate) then begin
		restore, star_dir + 'candidates_pdf.idl'
		print_struct, best_candidates
		which = question(/number, /int, 'which candidate would you like to explore?')
		candidate = best_candidates[which]
		print_struct, candidate
	endif
	zoom = 1.0
	@filter_parameters
	restore, star_dir + 'box_pdf.idl'
	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)	
	i_interesting = where(boxes.n[i_duration] gt 0)
	i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidate, i_oot=i_oot,  /box, n_intransit)];buffer=-candidate.duration/4,
	pad = long((max(boxes.hjd > candidate.hjd0) - min(boxes.hjd < candidate.hjd0))/candidate.period)+1

	nights = round(boxes.hjd - mearth_timezone())
	;transit_number = round((boxes.hjd - candidate.hjd0)/candidate.period)
	phased_time = (boxes.hjd - candidate.hjd0)/candidate.period + pad + 0.5
	orbit_number = long(phased_time)
	phased_time = (phased_time - orbit_number - 0.5)*candidate.period

			i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
			h = histogram(orbit_number[i_intransit], reverse_indices=ri)

;			h = histogram(nights[i_intransit], reverse_indices=ri)

			ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
		;	ri_lasts =ri[uniq(ri[0:n_elements(h)-1])+1]-1
			uniq_intransit =(ri[ri_firsts]); + ri[ri_firsts])/2; ri[((ri_firsts +ri_lasts)/2.)]
	events = round((boxes[i_intransit].hjd - candidate.hjd0)/candidate.period)

	uniq_events = events[uniq_intransit]
	if keyword_set(transit_number) then begin
		print, uniq_events
		i_event = where(uniq_events eq transit_number, n_event)
		i_event = i_event[0] > 0
	endif
	if ~keyword_set(i_event) then i_event = 0


		light_gray = 220
		gray = 150

		button_y = [-0.05, 0.05] + 0.93
		allleft = {x:[-0.05, 0.05]/2+0.08, y:[-0.02, 0.025] + 0.90, active:0B, label: '!C<<', charsize:1}
		left = {x:[-0.05, 0.05]/2+0.08, y:[-0.025, 0.02] + 0.96, active:0B, label: '!C<', charsize:1}
		intransit_images = {x:[-0.12, 0.12]+0.25, y: [-0.025, 0.02] + 0.96, active:0B, label:'!Iimages near transit', charsize:3}
		tonight_images = {x:[-0.12, 0.12]+0.25, y: [-0.02, 0.025] + 0.90, active:0B, label:'!Iimages tonight', charsize:3}
		zoom_in = {x:[0.17, 0.2]+0.25, y: [-0.02, 0.025] + 0.96, active:0B, label:'!lzoom in', charsize:3}
		zoom_out = {x:[0.17, 0.2]+0.25, y: [-0.02, 0.025] + 0.90, active:0B, label:'!lzoom out', charsize:3}
		zoom_left = {x:[0.13, 0.16]+0.25, y: [-0.02, 0.025] + 0.93, active:0B, label:'!IL', charsize:3}
		zoom_right = {x:[0.21, 0.24]+0.25, y: [-0.02, 0.025] + 0.93, active:0B, label:'!lR', charsize:3}

		zoom_vin = {x:[0.16, 0.18]+0.5, y: [-0.02, 0.025] + 0.96, active:0B, label:'!lvin', charsize:3}
		zoom_vout = {x:[0.16, 0.18]+0.5, y: [-0.02, 0.025] + 0.90, active:0B, label:'!lvout', charsize:3}



		commenting = {x:[0., 0.13]+0.5, y:[-0.025, 0.02] + 0.96, active:0B, label: '!Icomment', charsize:3}
		ignoring_night = {x:[0., 0.13]+0.5, y:[-0.02, 0.025] + 0.90, active:0B, label: '!Iflag night', charsize:3}
		ignoring_point = {x:[0, 0.17]+0.7, y:[-0.025, 0.02] + 0.96, active:0B, label: '!Iflag point', charsize:3}
		ignoring_ds9 = {x:[0, 0.17]+0.7, y:[-0.02, 0.025] + 0.90,active:0B, label: '!Iflag ds9', charsize:3}
		right = {x:[-0.05, 0.05]/2+0.92, y:[-0.025, 0.02] + 0.96, active:0B, label: '!C>', charsize:1}
		allright = {x:[-0.05, 0.05]/2+0.92, y:[-0.02, 0.025] + 0.90, active:0B, label: '!C>>', charsize:1}
		buttons = {left:left, intransit_images:intransit_images,tonight_images:tonight_images, commenting:commenting, ignoring_night:ignoring_night, ignoring_point:ignoring_point, ignoring_ds9:ignoring_ds9, right:right, zoom_in:zoom_in, zoom_out:zoom_out, zoom_left:zoom_left, zoom_right:zoom_right, zoom_vin:zoom_vin, zoom_vout:zoom_vout, allright:allright, allleft:allleft}


  	!mouse.button=1
	cleanplot, /silent

	while(!mouse.button lt 2 ) do begin
		xplot, 4, xpos=1000
		lc_plot, /time, /phased, eps=eps, anonymous=anonymous, zoom=zoom, shift=shift, scale=scale;, diag=diag, /top


	xplot, 7
	lc_plot, /phased, /time, sin=sin_params,anonymous=anonymous, zoom=zoom, shift=shift, scale=scale

		xplot, 5, xpos=1000
		lc_plot, /time, /phased, /binned, eps=eps, anonymous=anonymous, zoom=zoom, shift=shift, scale=scale;, diag=diag, /top


		xplot, 20, xpos=0

		box = {hjd:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n:0}
		box_number = uniq_events[i_event]
		box.hjd = candidate.hjd0 + box_number*candidate.period
		box.duration = candidate.duration
		box.depth = candidate.depth
		;box.depth_uncertainty = ?
		i_this =i_intransit[uniq_intransit[i_event]];where(abs(boxes.hjd - box.hjd) eq min(abs(boxes.hjd - box.hjd)), n_this)
; 		if n_this gt 0 then begin
; 			i_this = i_this[0]
			box.n = boxes[i_this].n[i_duration]
			box.depth = boxes[i_this].depth[i_duration]
			box.depth_uncertainty = boxes[i_this].depth_uncertainty[i_duration]
; 		endif

		lc_plot, /time, box=box, eps=eps,diagnosis=diagnosis, comparisons=comparisons, xmargin=[12,3], ymargin=[4, 10], lcs=lcs, censorship=censorship, /top, /event, zoom=zoom, shift=shift, scale=scale
		for i=0, n_tags(buttons)-1 do begin
			polyfill, /normal, buttons.(i).x[[0,0,1,1,0]], buttons.(i).y[[0,1,1,0,0]], thick=3, color=light_gray
			xyouts, /normal, mean(buttons.(i).x), mean(buttons.(i).y) + 0.01, align=0.5, charsize=buttons.(i).charsize, charthick=2, buttons.(i).label, color=gray*(1-buttons.(i).active)
		endfor
		if buttons.intransit_images.active then begin
			
			intransit_images, candidate, xpa_name=xpa_name, hjds=image_hjds, filenames=image_filenames,buffer=candidate.duration
			buttons.intransit_images.active=0
			flagged_in_ds9 = bytarr(n_elements(image_hjds))
		endif
		if buttons.tonight_images.active then begin
			tonight_images, box.hjd, xpa_name=xpa_name, hjds=image_hjds, filenames=image_filenames
			buttons.tonight_images.active=0
			flagged_in_ds9 = bytarr(n_elements(image_hjds))
		endif
		


		if buttons.commenting.active then begin
			comment_in_log
			buttons.commenting.active=0
			continue
		endif

		if buttons.ignoring_point.active then begin
			cursor, x_data, y_data, /down, /data
			normal_coords = convert_coord(x_data, y_data, /data, /to_normal)
			x = normal_coords[0]
			y = normal_coords[1]
			if y lt min(button_y) and !mouse.button eq 1 then begin
				print, x_data, y_data
				i_clicked = where(abs(lcs.cleaned.x - x_data) eq min(abs(lcs.cleaned.x - x_data)))
				print, 'clicked ', rw(i_clicked), ' at ', systime()
				censorship[i_clicked] = censorship[i_clicked] ne 1
			endif
		endif else begin
			if ~keyword_set(eps) then  cursor, x, y, /down, /normal
		endelse


		for i=0, n_tags(buttons)-1 do begin
			if x ge min(buttons.(i).x) and x le max(buttons.(i).x) and y ge min(buttons.(i).y) and y le max(buttons.(i).y) then buttons.(i).active = buttons.(i).active ne 1
		endfor
		if buttons.right.active then begin
			i_event = (i_event+1) < (n_elements(uniq_events)-1)
			shift = 0.0
			buttons.right.active = 0
		endif
		if buttons.left.active then begin
			i_event = (i_event-1) > 0
			shift = 0.0
			buttons.left.active=0
		endif

		if buttons.allright.active then begin
			i_event = (n_elements(uniq_events)-1)
			shift = 0.0
			buttons.allright.active = 0
		endif
		if buttons.allleft.active then begin
			i_event =  0
			shift = 0.0
			buttons.allleft.active=0
		endif

		if buttons.ignoring_ds9.active then begin
	
			spawn, 'xpaget ' + xpa_name + ' file', image_flagged
			i_match = where(strmatch(image_filenames, image_flagged), n_match)
			if n_match eq 1 then begin
				i_match = i_match[0]
				flagged_in_ds9[i_match] = flagged_in_ds9[i_match] ne 1
				if flagged_in_ds9[i_match] then begin
					spawn, 'xpaset -p '+ xpa_name +' cmap Blue; xpaset -p '+ xpa_name +' cmap invert yes  '
				endif else begin
					spawn, 'xpaset -p '+ xpa_name +' cmap Grey; xpaset -p '+ xpa_name +' cmap invert yes  '
				endelse
				print, ' USING DS9 TO FLAG:'
				i_flagged = where(flagged_in_ds9, n_flagged)
				for i=0, n_flagged-1 do	print, image_hjds[i_flagged[i]], ' = ', image_filenames[i_flagged[i]]
			endif else print, ' UH-OH - could not match up images between ds9 and IDL'

			buttons.ignoring_ds9.active = 0
		endif  
		if buttons.ignoring_night.active then begin
			
			tonight = round( box.hjd - mearth_timezone())
			i_tonight = where(round(lcs.cleaned.hjd - mearth_timezone()) eq tonight, n_tonight)
			if n_tonight gt 0 then censorship[i_tonight] = median(censorship[i_tonight]) ne 1
			buttons.ignoring_night.active=0
		endif
		if buttons.zoom_in.active then begin
			zoom *= 0.5
			buttons.zoom_in.active=0
		endif
		if buttons.zoom_out.active then begin
			zoom *= 2.0
			buttons.zoom_out.active=0
		endif

		if buttons.zoom_right.active then begin
			shift += 0.5
			buttons.zoom_right.active=0
		endif
		if buttons.zoom_left.active then begin
			shift -= 0.5
			buttons.zoom_left.active=0
		endif


		if buttons.zoom_vin.active then begin
			scale *= 0.5
			buttons.zoom_vin.active=0
		endif
		if buttons.zoom_vout.active then begin
			scale *= 2.0
			buttons.zoom_vout.active=0
		endif

	endwhile

	if n_elements(flagged_in_ds9) gt 0 then begin
		i_flagged = where(flagged_in_ds9, n_flagged)
		if n_flagged gt 0 then begin
			openw, raw_censor_lun, /get_lun, star_dir + 'raw_image_censorship.log', /append
			for i=0, n_flagged-1 do	printf, raw_censor_lun, string(format='(D13.7)', image_hjds[i_flagged[i]]) + ' = ' + image_filenames[i_flagged[i]] + ' was censored with ds9 on ' + systime()
			close, raw_censor_lun
			spawn, 'kwrite ' + star_dir + 'raw_image_censorship.log'
		endif
	endif
	
	if total(censorship, /int) ne n_elements(censorship) then begin
		openw, censor_lun, /get_lun, star_dir + 'censorship.log', /append
		i_censor=where(censorship eq 0, n_censor)
		for i=0, n_censor-1 do printf, censor_lun, string(format='(D13.7)', lcs.cleaned[i_censor[i]].hjd) + ' was censored by hand on ' + systime()
		close, censor_lun
		spawn, 'kwrite ' + star_dir + 'censorship.log'
	endif
	clear
END