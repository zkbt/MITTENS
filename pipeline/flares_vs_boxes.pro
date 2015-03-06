PRO flares_vs_boxes, flares, boxes, lc, flare_lc=flare_lc, necessary_flares=necessary_flares, templates=templates, fit=fit, priors=priors,  i_onflarenight=i_onflarenight, boxeskilledbyflares=boxeskilledbyflares
	common mearth_tools

	@filter_parameters
	flare_lc = lc
	flare_lc.flux = 0
	flare_threshold = 5
	nights = round(lc.hjd-mearth_timezone())
	uniq_nights = uniq(nights, sort(lc.hjd-mearth_timezone()))
boxeskilledbyflares = bytarr(n_elements(boxes))
	for i=0, n_elements(uniq_nights)-1 do begin
		; start assuming there are no flares
		flares_win = 0B
		tonight = nights[uniq_nights[i]]

		; pick out the interesting flares tonight
		i_flareconsider = where(round(flares.hjd - mearth_timezone()) eq tonight , n_flareconsider)
		if n_flareconsider eq 0 then continue

		; and the boxes
		i_boxconsider = where(round(boxes.hjd -mearth_timezone()) eq tonight, n_boxconsider)
		if n_boxconsider eq 0 then flares_win = 1B else begin
			tonights_boxes = boxes[i_boxconsider]
			i_interesting = where(tonights_boxes.n gt 0 and tonights_boxes.depth gt 0, n_interesting)
			if n_interesting eq 0 then flares_win = 1B else begin
				ai_interesting = array_indices(tonights_boxes.duration, i_interesting)
				i_epoch = ai_interesting[1,*]
				i_duration = ai_interesting[0,*]
				tonights_rescaling = tonights_boxes.rescaling
				if min(tonights_rescaling[ i_duration,i_epoch]) gt min(flares[i_flareconsider].rescaling) then flares_win =1B
			endelse
		endelse

		; if a flare gives a better fit than a box, consider it
		if flares_win then begin
			tonights_flares = flares[i_flareconsider]
			i_bestflare = where(-tonights_flares.height/tonights_flares.height_uncertainty eq max(-tonights_flares.height/tonights_flares.height_uncertainty), n_bestflare)
			i_bestflare = i_bestflare[0]
			ai_bestflare = array_indices(tonights_flares.height, i_bestflare)
			if n_elements(tonights_flares) gt 1 then i_epoch = ai_bestflare[1] else i_epoch =0L
			i_decay = ai_bestflare[0]
			sn_of_best_flare = -tonights_flares[i_epoch].height[i_decay]/tonights_flares[i_epoch].height_uncertainty[i_decay]
			if sn_of_best_flare gt flare_threshold then begin
				i_consider = where(round(lc.hjd - mearth_timezone()) eq tonight, n_consider)
				i_inflare = where(round(lc.hjd - mearth_timezone()) eq tonight and lc.hjd ge tonights_flares[i_epoch].hjd, n_inflare)
				flare_lc[i_inflare].flux =  tonights_flares[i_epoch].height[i_decay]*exp(-(lc[i_inflare].hjd - tonights_flares[i_epoch].hjd)/tonights_flares[i_epoch].decay_time[i_decay])
				i_boxconsider = where(round(boxes.hjd - mearth_timezone()) eq tonight, n_boxconsider)
				boxes[i_boxconsider].n *= 0
				boxeskilledbyflares[i_boxconsider] = 1
				if n_elements(necessary_flares) eq 0 then necessary_flares = {i_epoch:i_epoch, i_decay:i_decay} else begin
					if n_tags(necessary_flares) eq 0  then necessary_flares = {i_epoch:i_epoch, i_decay:i_decay} else necessary_flares = [necessary_flares, {i_epoch:i_epoch, i_decay:i_decay}]
				endelse
				this_flare =  tonights_flares[i_epoch]
; 				interactive, /on
; 				temp =fit_flare( lc, templates, fit, priors, this_flare, i_decay=(i_decay+0.001))
; 				interactive, /off
				if n_elements(i_onflarenight) eq 0 then i_onflarenight = i_consider else i_onflarenight = [i_onflarenight, i_consider]
			endif
		endif
	endfor
	if n_elements(i_onflarenight) eq 0 then i_onflarenight = -1
	if n_elements(necessary_flares) eq 0 then necessary_flares = -1
END
