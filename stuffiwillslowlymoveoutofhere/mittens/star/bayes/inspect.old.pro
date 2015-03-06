PRO inspect, candidate, eps=eps, diagnosis=diagnosis, comparisons=comparisons, transit_number=transit_number, sin_params=sin_params,longperiod=longperiod
	common this_star

	; pick a candidate, if one doesn't exist yet
 	if not keyword_set(candidate) then begin
		restore, star_dir + 'candidates_pdf.idl'
		print_struct, best_candidates
		which = question(/number, /int, 'which candidate would you like to explore?')
		candidate = best_candidates[which]
		print_struct, candidate
	endif
	zoom = 1.0
	@filter_parameters
	restore, star_dir() + 'box_pdf.idl'
	restore, star_dir() + 'cleaned_lc.idl'
	restore, star_dir() + 'variability_lc.idl'
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


;======================
; set up the buttons!
;======================

		light_gray = 220
		medium_gray = 170
		gray = 120

		textoffset =-0.004
		x_offset = 0.007
		y_offset = 0.003
		button_height = [-1, 1]*0.008
		button_width = [-1, 1]*0.01
		big = 6.0

		; display row
		buttons = {$
		show_event:{x:button_width*4.0, y:button_height, active:1B, label: 'event', charsize:1, row:0, uptodate:0},$
		show_orbit_phased:{x:button_width*big, y:button_height, active:1B, label: 'orbital phase', charsize:1, row:0, uptodate:0},$
		show_rot_phased:{x:button_width*7.0, y:button_height, active:0B, label: 'rotational phase', charsize:1, row:0, uptodate:0},$
		show_time:{x:button_width*3.0, y:button_height, active:0B, label: 'time', charsize:1, row:0, uptodate:0},$
		show_number:{x:button_width*2.0, y:button_height, active:0B, label: '#', charsize:1, row:0, uptodate:0},$
		show_boxsn:{x:button_width*4.0, y:button_height, active:0B, label:goodtex('D/\sigma_{MarPLE}'), charsize:1, row:0, uptodate:0},$
		show_correlations:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('correlations'), charsize:1, row:0, uptodate:0},$
		show_periodogram:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('periodogram'), charsize:1, row:0, uptodate:0},$
		show_marple:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('MarPLE'), charsize:1, row:0, uptodate:0},$

		; binning row
		option_event:{x:button_width*4.0, y:button_height/2.0 + 0.005, active:0B, label: '!Ubinned', charsize:0.8, row:1, uptodate:0},$
		option_orbit_phased:{x:button_width*big, y:button_height/2.0 + 0.005, active:0B, label: '!Ubinned', charsize:0.8, row:1, uptodate:0},$
		option_rot_phased:{x:button_width*7.0, y:button_height/2.0+ 0.005, active:0B, label: '!Ubinned', charsize:0.8, row:1, uptodate:0},$
		option_time:{x:button_width*3.0, y:button_height/2.0+ 0.005, active:0B, label: '!Ubinned', charsize:0.8, row:1, uptodate:0},$
		option_number:{x:button_width*2.0, y:button_height/2.0+ 0.005, active:0B, label: '!Ubinned', charsize:0.8, row:1, hide:1, uptodate:0},$
		option_boxsn:{x:button_width*4.0, y:button_height, active:0B, label:goodtex('D/\sigma_{MarPLE}'), charsize:1, row:1, hide:1, uptodate:0},$
		option_correlations:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('correlations'), charsize:1, row:1, hide:1, uptodate:0},$
		option_periodogram:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('periodogram'), charsize:1, row:1, hide:1, uptodate:0},$
		option_marple:{x:button_width*6.0, y:button_height, active:0B, label:goodtex('MarPLE'), charsize:1, row:1, hide:1, uptodate:0},$

		; navigation row
		allleft:{x:button_width*2.0, y:button_height, active:0B, label: '<<', charsize:1, row:2, uptodate:0},$
		left:{x:button_width*2.0, y:button_height, active:0B, label: '<', charsize:1, row:2, uptodate:0},$
		mode_candidate:{x:button_width*4.0, y:button_height, active:1B, label: 'phased', charsize:1, row:2, uptodate:0},$
		mode_events:{x:button_width*7.0, y:button_height, active:0B, label: 'best events', charsize:1, row:2, uptodate:0},$
		mode_night:{x:button_width*4.0, y:button_height, active:0B, label: 'nights', charsize:1, row:2, uptodate:0},$
		right:{x:button_width*2.0, y:button_height, active:0B, label: '>', charsize:1, row:2, uptodate:0},$
		allright:{x:button_width*2.0, y:button_height, active:0B, label: '>>', charsize:1, row:2, uptodate:0},$
		; zoom row
		zoom_in:{x:button_width*big, y:button_height, active:0B, label:'magnify time', charsize:1, row:3, uptodate:0},$
		zoom_out:{x:button_width*big, y:button_height, active:0B, label:'shrink time', charsize:1, row:3, uptodate:0},$
		zoom_left:{x:button_width*big, y: button_height, active:0B, label:'shift left', charsize:1, row:3, uptodate:0},$
		zoom_right:{x:button_width*big, y:button_height, active:0B, label:'shift right', charsize:1, row:3, uptodate:0},$
		zoom_vin:{x:button_width*big, y:button_height, active:0B, label:'magnify flux', charsize:1, row:3, uptodate:0},$
		zoom_vout:{x:button_width*big, y:button_height , active:0B, label:'shrink flux', charsize:1, row:3, uptodate:0},$
		; images and censoring row
		intransit_images:{x:button_width*9.0, y:button_height, active:0B, label:'images near transit', charsize:1, row:4, uptodate:0},$
		tonight_images:{x:button_width*7.0, y:button_height, active:0B, label:'images tonight', charsize:1, row:4, uptodate:0},$
		ignoring_night:{x:button_width*5.0, y:button_height , active:0B, label:'flag night', charsize:1, row:4, uptodate:0},$
		ignoring_point:{x:button_width*5.0, y:button_height , active:0B, label:'flag point', charsize:1, row:4, uptodate:0},$
		ignoring_ds9 :{x:button_width*5.0, y:button_height , active:0B, label:'flag ds9', charsize:1, row:4, uptodate:0},$
		; posting row		
		commenting:{x:button_width*big, y:button_height , active:0B, label:'comment', charsize:1, row:5, uptodate:0},$
		eps:{x:button_width*big, y:button_height , active:0B, label:'save to eps', charsize:1, row:5, uptodate:0},$
		png:{x:button_width*big, y:button_height , active:0B, label:'save to png', charsize:1, row:5, uptodate:0},$
		post:{x:button_width*big, y:button_height , active:0B, label:'post to blog', charsize:1, row:5, uptodate:0}$
		}
		rowcount = buttons.(0).row
		for j=1, n_tags(buttons)-1 do  rowcount = [rowcount, buttons.(j).row]
		n_rows = n_elements(uniq(rowcount, sort(rowcount)))

		y_position = 0.98
		for i=0, n_rows-1 do begin
			onthisrow = bytarr(n_tags(buttons))
			total_width = 0.0
			for j=0, n_tags(buttons)-1 do begin
				if buttons.(j).row eq i then begin
					width = max(buttons.(j).x) - min(buttons.(j).x)
					total_width += width
				endif
			endfor
			x_position = 0.5 - total_width/2.0
			for j=0, n_tags(buttons)-1 do begin
				if buttons.(j).row eq i then begin
					width = max(buttons.(j).x) - min(buttons.(j).x)
					buttons.(j).x += x_position + width/2.0
					x_position += width+x_offset
					buttons.(j).y += y_position
					y_jump = max(buttons.(j).y ) - min(buttons.(j).y)
				endif
			endfor
			y_position -= y_jump + y_offset
		endfor

		

;======================
; start feedback loop
;======================

  	!mouse.button=1
	cleanplot, /silent
	screensize = get_screen_size()

	while(!mouse.button lt 2 ) do begin

		;---------------------------------
		; choose which event/night to display
		;---------------------------------
		box = {hjd:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n:0}

		if buttons.mode_candidate.active then begin
			box_number = uniq_events[i_event]
			box.hjd = candidate.hjd0 + box_number*candidate.period
			box.duration = candidate.duration
			box.depth = candidate.depth
			;box.depth_uncertainty = ?
			i_this =i_intransit[uniq_intransit[i_event]];where(abs(boxes.hjd - box.hjd) eq min(abs(boxes.hjd - box.hjd)), n_this)
			box.n = boxes[i_this].n[i_duration]
			box.depth = boxes[i_this].depth[i_duration]
			box.depth_uncertainty = boxes[i_this].depth_uncertainty[i_duration]
		endif

		; ---------------------------------
		; handle saving
		; ---------------------------------
		if buttons.eps.active then begin
			eps=1
			for i=0, n_tags(buttons)-1 do  buttons.(i).uptodate = 0
		endif

		;-----------------------------------
		; show which plots need to be shown
		; ----------------------------------
		xpos = 0
		ypos = 0

		if buttons.show_event.active then begin
			xplot, 11
			n_bins = ( max(cleaned_lc.hjd) - min(cleaned_lc.hjd))/(candidate.duration)*4
			lc_plot, xpos=xpos, ypos=ypos, /time, box=box, eps=eps,diagnosis=diagnosis, comparisons=comparisons, xmargin=[12,3], ymargin=[4, 10], lcs=lcs, censorship=censorship, /top, /event, zoom=zoom, shift=shift, scale=scale, binned=buttons.option_event.active, n_bins=n_bins
		endif
			xsize = screensize[0]/3
			ysize= xsize*0.5
		xpos += xsize
		if buttons.show_time.active and buttons.show_time.uptodate eq 0 then begin
			ypos += ysize
			xplot, 14, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
			lc_plot, xpos=xpos, ypos=ypos, /time, eps=eps, anonymous=anonymous;, diag=diag, /top
	;		buttons.show_time.uptodate = 1
		endif

		if buttons.show_orbit_phased.active and buttons.show_orbit_phased.uptodate eq 0  then begin
			ypos+=ysize
			xplot, 4, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
			interactive_lc_plot, xpos=xpos, ypos=ypos, /time, /phased, eps=eps, anonymous=anonymous, binned=buttons.option_orbit_phased.active;, zoom=zoom, shift=shift, scale=scale, 
	;		buttons.show_orbit_phased.uptodate = 1
		endif ;else wdelete, 4

		if buttons.show_rot_phased.active then begin
			if n_elements(sin_params) eq 0 then begin
				ypos += ysize
				xplot, 8, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
				periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1+1.0*keyword_set(longperiod), 100+100.*keyword_set(longperiod)], sin_params=sin_params
			endif
			ypos += ysize
			xplot, 7, xsize=xsize, ysize=ysize, xpos=xpos, ypos=ypos
			lc_plot, xpos=xpos, ypos=ypos, /phased, /time, sin=sin_params,anonymous=anonymous, shift=shift, scale=scale, binned=buttons.option_rot_phased.active, eps=eps
		endif

		if buttons.show_boxsn.active then begin
			; plot the boxes
			cleanplot, /silent
			xsize = screensize[0]/3
			ysize= xsize/3
			xpos = screensize[0] - xsize
			ypos = screensize[1] ;- screensize[0]/4.5
			xplot, 15, title=star_dir() + ' + S/N of hypothetical individual transits', xsize=xsize, ysize=ysize, xpos=xpos , ypos=ypos
			plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=candidate
			loadct, 0, /silent
		endif

		if buttons.show_correlations.active then begin
			; plot the residuals
			cleanplot, /silent
			loadct, 0, /silent
			smultiplot, /def
			xsize = screensize[0]/3
			ysize= xsize/1.5
			ypos = screensize[1]-  ysize - screensize[0]/3/3
			xpos = screensize[0] - xsize
		
			xplot, xsize=xsize, ysize=ysize,  16, title=star_dir + ' + correlations', xpos=xpos, ypos=ypos, top=top
			plot_residuals, /top
		endif

		if buttons.show_marple.active then begin
			cleanplot, /silent
			xsize = screensize[0]/3
			ysize= xsize*2
			loadct, 0
			xplot, 13, xsize=xsize, ysize=ysize
			marpleplot_griddemo, round(uniq_events[i_event]*candidate.period + candidate.hjd0)
			loadct, 0
		endif

		if buttons.eps.active then begin
			eps =0
			buttons.eps.active = 0
			continue
		endif
		wset, 11


		; -----------------------------------
		; draw the buttons!
		; -----------------------------------
		for i=0, n_tags(buttons)-1 do begin
			if ~tag_exist(buttons.(i), 'HIDE') then begin
				polyfill, /normal, buttons.(i).x[[0,0,1,1,0]], buttons.(i).y[[0,1,1,0,0]], thick=2, color=light_gray
				plots, /normal, buttons.(i).x[[0,0,1,1,0]], buttons.(i).y[[0,1,1,0,0]], thick=1, color=medium_gray*(1-buttons.(i).active)
				xyouts, /normal, mean(buttons.(i).x), mean(buttons.(i).y) + textoffset, align=0.5, charsize=buttons.(i).charsize, charthick=1.5, buttons.(i).label, color=gray*(1-buttons.(i).active)
			endif
		endfor

		;----------------------------------
		; handle censoring and image showing
		;----------------------------------
		
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

		;----------------------------------
		; figure out if a button has been pushed
		;----------------------------------
		for i=0, n_tags(buttons)-1 do begin
			if x ge min(buttons.(i).x) and x le max(buttons.(i).x) and y ge min(buttons.(i).y) and y le max(buttons.(i).y) then buttons.(i).active = buttons.(i).active ne 1
		endfor


		;----------------------------------
		; handle navigation
		;----------------------------------
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


		;----------------------------------
		; handle more censoring?
		;----------------------------------
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


		;----------------------------------
		; handle zooming
		;----------------------------------
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