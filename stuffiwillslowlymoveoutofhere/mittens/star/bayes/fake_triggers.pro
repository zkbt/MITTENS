PRO fake_triggers, n, remake=remake, play=play, profile=profile

	; diagnose the slow bits (probably occultnl)
	if keyword_set(profile) then begin
		profiler, /reset
		profiler, /system
		profiler
		fake_triggers, n, remake=remake
		profiler, /report, output=output, data=data
		i = reverse(sort(data.time)) 
		print_struct, data[i]
;		if question('do you want to look at the profiler results?', /int) then stop
		return
	endif

	; basics
	common this_star
	common mearth_tools
	@constants
	@filter_parameters
	if not keyword_set(n) then n=50000

	; figure out root star directory (whether or not already working on a fake)
	ls = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, star_dir, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, star_dir, 'te[0-9]+'), '[0-9]+'))
	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')

	; skip if this is already finished
	if is_uptodate(star_dir + fake_trigger_dir + 'injected_and_recovered.idl', star_dir + 'target_lc.idl') and ~ keyword_set(remake) then begin
		mprint, skipping_string, 'fake triggered candidates are up to date';'already faked lots of triggers for this star! run fake_trigger again with /remake, if you want.'
		return
	endif
	; regenerate the original pdf, and set up the fake directory
;	if is_uptodate( star_dir + 'fakes_setup.idl', star_dir + 'box_pdf.idl') eq 0 then 

;lc_to_pdf, /fake_setup, /remake, /squash_flares

	; setup fake directory, copying files necessary for plotting into it
	file_mkdir, star_dir + fake_trigger_dir
	file_copy, star_dir + 'raw_target_lc.idl', star_dir + fake_trigger_dir + 'raw_target_lc.idl', /over
	file_copy, star_dir + 'raw_ext_var.idl', star_dir + fake_trigger_dir + 'raw_ext_var.idl', /over
	file_copy, star_dir + 'ext_var.idl', star_dir + fake_trigger_dir + 'ext_var.idl', /over
	file_copy, star_dir + 'sfit.idl', star_dir + fake_trigger_dir + 'sfit.idl', /over

	; load up environment full of variables that were defined or restored into lc_to_pdf.pro
	if is_uptodate( star_dir + 'fakes_setup.idl', star_dir + 'box_pdf.idl') eq 0 then lc_to_pdf, /fake_setup, /remake, /squash
	restore, star_dir + 'fakes_setup.idl'
	restore, star_dir + 'ext_var.idl'
	exptime = median(ext_var.exptime)
	overheadtime = 20.0
	delaytime = 120.0

		i_seasonwide_rescaling = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_seasonwidematch)
		if n_seasonwidematch eq 1 then seasonwide_rescaling = priors[i_seasonwide_rescaling].coef
	; only look at the boxes that contain at least one data point
	boxes = boxes[where(total(boxes.n, 1) gt 0)]

	p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
	pad = long((max(boxes.hjd) - min(boxes.hjd))/p_min)+1

 	boxes_nights = long(boxes.hjd -mearth_timezone())
	flares_nights = long(flares.hjd -mearth_timezone())
	initial_boxes = boxes
	initial_flares = flares
	lc = inflated_lc
	nights = round(lc.hjd - mearth_timezone())
	uniq_nights = nights[uniq(nights)]
	struct = {period:0.0d, hjd0:0.0d, duration:0.0, t23:0.0, t14:0.0, b:0.0, radius:0.0, depth:0.0, depth_uncertainty:0.0, n_untriggered_sigma:0.0, n_sigma:0.0,  n_points:0, n_nights:0, n_points_before:0,  rescaling:1.0, transit_hjd:0.0d, time_left:0.0, exposures_left:0.0, trigger_bump:0.0, rednoise:0.0,  preinjection_depth_uncertainty:0.0}
	injected = replicate(struct, n)
	recovered = replicate(struct, n)
	temp_random_event_injected = {which_fake:0L, depth:0.0, depth_uncertainty:0.0, n_untriggered_sigma:0.0, n_sigma:0.0,  n_points:0, n_nights:0, n_points_before:0, transit_hjd:0.0, time_left:0.0, exposures_left:0.0, rednoise:0.0, rescaling:1.0, trigger_bump:0.0, preinjection_depth_uncertainty:0.0}
	temp_random_event_recovered = temp_random_event_injected
	bundle_of_injected = replicate(temp_random_event_injected, n)
	bundle_of_recovered = bundle_of_injected

	n_data = n_elements(lc)

	; warm up the time machine (precalculate all the priors)
	for i=1, n_elements(uniq_nights)-1 do begin
		the_night_before = uniq_nights[i]
		; figure out what priors we can use, that only include data up to the event we're looking at
	 	priors_filename = star_dir + fake_trigger_dir + 'timemachine_priors_' + rw(the_night_before) + '.idl'
		print, 'looking for ', priors_filename
		if file_test(priors_filename) then begin
			print, '    found it, loading it up!'
		endif else begin
			print, "    couldn't find it, rerunning lc_to_pdf in timemachine mode"
			lc_to_pdf, /remake, timemachine=the_night_before, /squash
		endelse
		restore, priors_filename
		if i eq 1 then begin
			archive_of_priors = create_struct('UPTO'+rw(the_night_before), priors)
			archive_of_fits = create_struct('UPTO'+rw(the_night_before), spliced_clipped_season_fit)
		endif else begin
			archive_of_priors = create_struct(archive_of_priors, 'UPTO'+rw(the_night_before), priors)
			archive_of_fits = create_struct(archive_of_fits, 'UPTO'+rw(the_night_before), spliced_clipped_season_fit)

		endelse
	endfor
	tags = tag_names(archive_of_priors)
	archive_nights = long(stregex(/ex, tags, '[0-9]+'))
	restore, star_dir + 'fakes_setup.idl'
;radii = [4.0, 3.0, 2.5, 2.2, 2.0]

	; changing the star directory to the fake one - don't forget to change it back!
;	star_dir = star_dir + fake_trigger_dir

	i_count = 0
	; loop over how many iterations we want to run
	for i=0L, n-1 do begin 

		; inject the transit
		if keyword_set(input_injected) then injected[i] = input_injected else begin
			copy_struct, generate_fake(), struct
			injected[i] = struct
		endelse

		; do some more calculations on the injected transit
		a_over_rs = a_over_rs(lspm_info.mass, lspm_info.radius, injected[i].period)
		injected[i].depth = (injected[i].radius*0.00917/lspm_info.radius)^2; (injected[i].radius*r_earth/r_sun/lspm_info.radius)^2
		rp_over_rs = sqrt(injected[i].depth)
		injected[i].t14 = (injected[i].period/!pi*asin(sqrt((1.0+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
		injected[i].t23 = (injected[i].period/!pi*asin(sqrt((1.0-rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
		injected[i].duration = injected[i].t23
		
		; figure out which points are in-transit, set dial of time machine
		i_intransit = where_intransit(lc, injected[i], i_oot=i_oot, n_intransit)
		transit = fltarr(n_data)
		if n_intransit gt 0 then begin
			sinphi = sin(!pi*injected[i].t14/injected[i].period)
			inclination = acos(sqrt(((1.0 + injected[i].radius*r_earth/lspm_info.radius/r_sun)^2/a_over_rs^2 - sinphi^2)/(1.0 - sinphi^2)))
			transit = -2.5*alog10( zeroeccmodel(lc.hjd,injected[i].hjd0,injected[i].period,lspm_info.mass,lspm_info.radius,injected[i].radius*r_earth/r_sun,inclination,0.0,0.24,0.38) )
			transit_numbers = round((lc[i_intransit].hjd - injected[i].hjd0)/injected[i].period)
			uniq_transits = uniq(round(transit_numbers), sort(transit_numbers))

			; loop over transits that fall within the dataset; set time machine to those dates
			for j=0, n_elements(uniq_transits)-1 do begin
				transit_hjd_number = transit_numbers[uniq_transits[j]]
				the_night_before = min(round(injected[i].hjd0 + transit_hjd_number*injected[i].period - mearth_timezone()) - 1)
				i_points_in_this_transit = i_intransit[where(transit_numbers eq transit_hjd_number)]

	
				if total(/int, uniq_nights le the_night_before) le 1 then continue
		
				; inject the transit, blank out all data after the transit
				injected_lc = lc
				injected_lc.flux += transit		
				injected_lc.okay = injected_lc.okay and lc.hjd le max(lc[i_points_in_this_transit].hjd)
		
				
				i_thisdate = value_locate(archive_nights, the_night_before)  
				priors = archive_of_priors.(i_thisdate)
				fit = archive_of_fits.(i_thisdate)
			;	print, 'date is ', the_night_before, '; using ', archive_nights[i_thisdate]	
				duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
				i_duration = value_locate(boxes[0].duration-duration_bin/2, recovered[i].duration) > 0
		
				; fit the in-transit box
				this_event_center = (injected[i].hjd0 + injected[i].period*transit_hjd_number)
				i_intransitbox = where(abs(initial_boxes.hjd - this_event_center) eq min(abs(initial_boxes.hjd - this_event_center)), n_intransitbox)
				i_intransitbox = i_intransitbox[0]
		
				boxes = initial_boxes[0:i_intransitbox]

				; before injecting the transit
	;			temp_random_event_recovered.preinjection_depth = boxes[i_intransitbox].depth[i_duration]
				temp_random_event_recovered.preinjection_depth_uncertainty = boxes[i_intransitbox].depth_uncertainty[i_duration]

			;	fit =spliced_clipped_season_fit
				boxes[i_intransitbox] =  fit_box(injected_lc, templates,fit, priors, boxes[i_intransitbox], demo_plot=demo_plot, i_duration=i_duration)	


				box_rednoise_variance = fltarr(n_elements(boxes[0].depth))
		;		for iii=0, n_elements(boxes[0].depth)-1 do begin
					iii = i_duration

					temp_rednoise = -0.1	
					converged = 0
					while(~converged) do begin
						temp_rednoise += 0.1		; go a little coarser to speed up simulation
						i_interesting = where(boxes.n[iii] gt 0, n_interesting)
						rednoise_correction = sqrt(1.0 + boxes[i_interesting].n[iii]*temp_rednoise^2);/(1.0 + temp_rednoise^2)
						converged = 1.48*mad(boxes[i_interesting].depth[iii]/boxes[i_interesting].depth_uncertainty[iii]/rednoise_correction) le 1.0 or temp_rednoise gt 2
					endwhile
					box_rednoise_variance[iii] = temp_rednoise^2
					boxes[i_interesting].depth_uncertainty[iii] *= rednoise_correction
		;		endfor
			
				temp_random_event_injected.depth = injected[i].depth
				temp_random_event_injected.which_fake = i
				temp_random_event_injected.depth_uncertainty = sqrt(1.0/total(1.0/lc[i_points_in_this_transit].fluxerr^2))*seasonwide_rescaling
				temp_random_event_injected.n_nights = total(/int, uniq_nights le the_night_before)
				temp_random_event_injected.n_points_before = total(/int, lc.hjd le the_night_before)
				temp_random_event_injected.n_points = n_elements(i_points_in_this_transit)
				temp_random_event_injected.rescaling = seasonwide_rescaling 
				temp_random_event_injected.rednoise = 1.0 
				temp_random_event_injected.n_untriggered_sigma = temp_random_event_injected.depth/temp_random_event_injected.depth_uncertainty
				temp_random_event_injected.transit_hjd = boxes[i_intransitbox].hjd

				; figure out time left after transit, can a trigger bump be realized?
				first_post_transit_point = min(where(lc.hjd gt (injected[i].hjd0 + transit_hjd_number*injected[i].period + injected[i].t14/2.0 )))
				if first_post_transit_point gt 0 then begin
					time_to_next_point = lc[first_post_transit_point].hjd - lc[max(i_points_in_this_transit)].hjd
					if time_to_next_point lt 1.0/24.0 then begin
						temp_random_event_injected.time_left = injected[i].hjd0 + transit_hjd_number*injected[i].period + injected[i].t23/2.0 - max(lc[i_points_in_this_transit].hjd)
						temp_random_event_injected.exposures_left =  ((24*60*60*temp_random_event_injected.time_left - delaytime) > 0)/(exptime + overheadtime)
					endif
				endif
				temp_random_event_injected.trigger_bump = sqrt(temp_random_event_injected.exposures_left/temp_random_event_injected.n_points + 1.0)
				temp_random_event_injected.n_sigma = temp_random_event_injected.n_untriggered_sigma*temp_random_event_injected.trigger_bump
				copy_struct, temp_random_event_injected, temp_random_event_recovered


				i_rescaling = where(strmatch(fit.name, '*RESCALING'), n_rescalingmatch)
				if n_rescalingmatch eq 1 then temp_random_event_recovered.rescaling = fit[i_rescaling].coef else temp_random_event_recovered.rescaling=-1
				temp_random_event_recovered.rednoise = sqrt(box_rednoise_variance[i_duration])
				recovered[i].duration =  injected[i].duration
				recovered[i].period = injected[i].period
				recovered[i].hjd0 = injected[i].hjd0
				recovered[i].radius = injected[i].radius
				recovered[i].t23 = injected[i].t23
				recovered[i].t14 = injected[i].t14
				recovered[i].b = injected[i].b
				temp_random_event_recovered.depth = boxes[i_intransitbox].depth[i_duration]
				temp_random_event_recovered.depth_uncertainty = boxes[i_intransitbox].depth_uncertainty[i_duration]
				temp_random_event_recovered.n_nights = temp_random_event_injected.n_nights
				temp_random_event_recovered.n_points = boxes[i_intransitbox].n[i_duration]
		
				temp_random_event_recovered.n_untriggered_sigma = temp_random_event_recovered.depth/temp_random_event_recovered.depth_uncertainty
				temp_random_event_recovered.trigger_bump = sqrt(temp_random_event_recovered.exposures_left/temp_random_event_recovered.n_points + 1.0)/sqrt(1.0 + (temp_random_event_recovered.exposures_left+temp_random_event_recovered.n_points)*box_rednoise_variance[i_duration])*sqrt(1.0 + temp_random_event_recovered.n_points*box_rednoise_variance[i_duration])
				temp_random_event_recovered.n_sigma = temp_random_event_recovered.n_untriggered_sigma*temp_random_event_recovered.trigger_bump


		;		temp_random_event_recovered.affected_by_flare = total(boxeskilledbyflares[i_intransitboxes[uniq_intransit]])
				if temp_random_event_recovered.n_points eq 0 then temp_random_event_recovered.n_sigma =0


				if temp_random_event_recovered.n_sigma gt recovered[i].n_sigma then begin
					temp_struct = injected[i]
					copy_struct, temp_random_event_injected, temp_struct
					injected[i] = temp_struct

					temp_struct = recovered[i]
					copy_struct, temp_random_event_recovered, temp_struct
					recovered[i] = temp_struct				
				endif
				if i_count lt n then begin
					bundle_of_injected[i_count] = temp_random_event_injected
					bundle_of_recovered[i_count] = temp_random_event_recovered
				endif
				i_count += 1
; 				if n_elements(bundle_of_injected) eq 0 then bundle_of_injected = temp_random_event_injected else bundle_of_injected = [bundle_of_injected, temp_random_event_injected]
; 				if n_elements(bundle_of_recovered) eq 0 then bundle_of_recovered = temp_random_event_recovered else bundle_of_recovered = [bundle_of_recovered, temp_random_event_recovered]
			endfor
	
			; plot results			
	; 		if keyword_set(display) and keyword_set(not_fake) then begin
	; 			cleanplot, /silent
	; 			xplot, 3, title='S/N for "Box" Events', xsize=950, ysize=300
	; 			plot_boxes, boxes;, mark=i_intransitboxes[uniq_intransit]
	; 
	; 		endif
	; 			print, 'injected'
	; 			print_struct, injected[i]
	; 			print, 'recovered'
	; 			print_struct, recovered[i]
			cleanplot
; 			if i gt 10 and i mod 500 eq 0 then begin
; 				i_radius = where(injected[bundle_of_injected.which_fake].radius lt 10 and injected[bundle_of_injected.which_fake].b lt 0.3 and bundle_of_injected.n_points gt 0, n_rad)
; 				if n_rad gt 1 then plot_binned, psym=1, bundle_of_injected[i_radius].n_nights, bundle_of_recovered[i_radius].n_sigma/bundle_of_injected[i_radius].n_sigma, yr=[-2, 2], n_bins=max(bundle_of_injected.n_nights), xr=[0, max(bundle_of_injected.n_nights)]
; 			endif
	
			if i gt 10 and i mod 2000 eq 0 then begin
; 				plot, psym=3, recovered.n_untriggered_sigma, recovered.n_sigma, /nodata, /iso
; 				plots, recovered.n_untriggered_sigma, recovered.n_sigma, color=recovered.exposures_left/max(recovered.exposures_left)
		;		xplot, xsize=1000, ysize=1000
		;		loadct, 39
		;		plot_nd, recovered, psym=3, dye=recovered.exposures_left
			endif
	
			; if just playing around, then ask if you want to look at fake candidates
			if question('curious', interactive=play) or keyword_set(input_injected) then begin
				print, star_dir
				inflated_lc = injected_lc
				target_lc = injected_lc
				save, filename=star_dir + fake_trigger_dir +'inflated_lc.idl', inflated_lc, templates
				save, filename=star_dir + fake_trigger_dir +'box_pdf.idl', boxes,  priors, spliced_clipped_season_fit, box_rednoise_variance
				save, filename=star_dir + fake_trigger_dir +'flares_pdf.idl', flares, flare_lc, necessary_flares, i_onflarenight
	
				best_candidates = [injected[i], recovered[i]]
				save, filename=star_dir + fake_trigger_dir +'candidates_pdf.idl', best_candidates
				star_dir = star_dir + fake_trigger_dir
				explore_pdf, /fake, 1, transit_number=transit_hjd_number
				star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
	
			endif
			if i mod 100 eq 0 then counter, i, n, /time, starttime=starttime, tab_string + tab_string + tab_string+ 'fake trigger #'
		endif
; 		print_struct, injected[i]
; 		print_struct, bundle_of_injected
; 		print_struct, recovered[i]
; 		print_struct, bundle_of_recovered   
; 		if question(/int, 'hey') then stop

	endfor

	save, filename=star_dir + fake_trigger_dir +  'injected_and_recovered.idl', injected, recovered
	save, filename=star_dir + fake_trigger_dir +  'bundles_injected_and_recovered.idl', bundle_of_injected, bundle_of_recovered
END