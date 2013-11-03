

PRO fake_pdfs, n, profile=profile, demo_plot=demo_plot, remake=remake, input_injected, input_recovered

	; diagnose the slow bits (probably occultnl)
	if keyword_set(profile) then begin
		profiler, /reset
		profiler, /system
		profiler
		fake_pdfs, n, remake=remake
		profiler, /report, output=output, data=data
		i = reverse(sort(data.time)) 
		print_struct, data[i]
;		if question('do you want to look at the profiler results?', /int) then stop
		return
	endif

	common this_star
	common mearth_tools
	ls = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, star_dir, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, star_dir, 'te[0-9]+'), '[0-9]+'))
	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')

	if is_uptodate(star_dir + fake_dir + 'injected_and_recovered.idl', star_dir + 'target_lc.idl') and ~ keyword_set(remake) and ~keyword_set(input_injected) then begin
		mprint, skipping_string, 'fake phased candidates are up to date'
		return
	endif


	; regenerate the original pdf, and set up the fake directory
	if is_uptodate( star_dir + 'fakes_setup.idl', star_dir + 'box_pdf.idl') eq 0 then lc_to_pdf, /fake_setup, /remake, /squash_flares

	; setup fake directory
	file_mkdir, star_dir + fake_dir
	file_copy, star_dir + 'raw_target_lc.idl', star_dir + fake_dir + 'raw_target_lc.idl', /over
	file_copy, star_dir + 'raw_ext_var.idl', star_dir + fake_dir + 'raw_ext_var.idl', /over
	file_copy, star_dir + 'ext_var.idl', star_dir + fake_dir + 'ext_var.idl', /over
	file_copy, star_dir + 'sfit.idl', star_dir + fake_dir + 'sfit.idl', /over
	@constants
	@filter_parameters
	if not keyword_set(n) then n=1000

	; load up environment
	restore, star_dir + 'ext_var.idl'
	restore, star_dir + 'fakes_setup.idl'

	; only look at the boxes that contain at least one data point
	boxes = boxes[where(total(boxes.n, 1) gt 0)]

	p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
	pad = long((max(boxes.hjd) - min(boxes.hjd))/p_min)+1


 	boxes_nights = long(boxes.hjd -mearth_timezone())
	flares_nights = long(flares.hjd -mearth_timezone())
	initial_boxes = boxes
	initial_flares = flares
	lc = inflated_lc
	struct = {period:0.0d, hjd0:0.0d, duration:0.0,  t23:0.0, t14:0.0, depth:0.0, depth_uncertainty:0.0, n_sigma:0.0, b:0.0, radius:0.0, n_boxes:0, n_points:0, affected_by_flare:0, n_sigma_bestevent:0.0, rescaling:1.0,  preinjection_depth_uncertainty:0.0}
	injected = replicate(struct, n)
	recovered = replicate(struct, n)
	n_data = n_elements(lc)
	star_dir = star_dir + fake_dir
	if keyword_set(input_injected) then begin
		n = 1
	endif
	for i=0L, n-1 do begin 
		; inject the transit
		if keyword_set(input_injected) then injected[i] = input_injected else begin
			copy_struct, generate_fake(), struct
			injected[i] = struct
		endelse
		
		a_over_rs = a_over_rs(lspm_info.mass, lspm_info.radius, injected[i].period)
		injected[i].depth = (injected[i].radius*0.00917/lspm_info.radius)^2; (injected[i].radius*r_earth/r_sun/lspm_info.radius)^2
		rp_over_rs = sqrt(injected[i].depth)
		injected[i].t14 = (injected[i].period/!pi*asin(sqrt((1.0+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
		injected[i].t23 = (injected[i].period/!pi*asin(sqrt((1.0-rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
		injected[i].duration = injected[i].t23
		
	;	injected[i].duration = (injected[i].period/!pi*asin(sqrt((1+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
		i_intransit = where_intransit(lc, injected[i], i_oot=i_oot, n_intransit)
		injected[i].n_points = n_intransit
		transit = fltarr(n_data)
		if n_intransit gt 0 then begin
			sinphi = sin(!pi*injected[i].t14/injected[i].period)
			inclination = acos(sqrt(((1.0 + injected[i].radius*r_earth/lspm_info.radius/r_sun)^2/a_over_rs^2 - sinphi^2)/(1.0 - sinphi^2)))
			transit = -2.5*alog10( zeroeccmodel(lc.hjd,injected[i].hjd0,injected[i].period,lspm_info.mass,lspm_info.radius,injected[i].radius*r_earth/r_sun,inclination,0.0,0.24,0.38) )
		;	print, i, injected[i].period,lspm_info.mass,lspm_info.radius,injected[i].radius*r_earth/r_sun,inclination,0.0,0.24,0.38, injected[i].b
;			transit[i_intransit] += injected[i].depth
			transit_numbers = (lc[i_intransit].hjd - injected[i].hjd0)/injected[i].period
			uniq_transits = uniq(round(transit_numbers), sort(transit_numbers))
			injected[i].n_boxes = n_elements(uniq_transits)
			injected[i].depth_uncertainty = sqrt(1.0/total(1.0/lc[i_intransit].fluxerr^2))
			injected[i].n_sigma = injected[i].depth/injected[i].depth_uncertainty
		endif
		injected_lc = lc
		injected_lc.flux += transit		

			recovered[i].duration =  injected[i].duration
			duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
			i_duration = value_locate(boxes[0].duration-duration_bin/2, recovered[i].duration) > 0
;			recovered[i].duration = boxes[0].duration[i_duration]

		; fit the in-transit boxes
		boxes = initial_boxes
		i_intransitboxes = where_intransit(boxes, injected[i], n_intransitboxes, /box)
		flares = initial_flares
		if n_intransitboxes gt 0 then begin


			phased_time = (boxes.hjd - injected[i].hjd0)/injected[i].period + pad + 0.5
			orbit_number = long(phased_time)
			phased_time = (phased_time - orbit_number - 0.5)*injected[i].period
			i_intransitboxes = i_intransitboxes[sort(abs(phased_time[i_intransitboxes]))]
			h = histogram(boxes_nights[i_intransitboxes], reverse_indices=ri)
			ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
			uniq_intransit =(ri[ri_firsts])



		;	recovered[i].preinjection_depth = 0.0;total(boxes[i_intransitboxes[uniq_intransit]].depth[i_duration]/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2)/ total(1.0/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2)
			recovered[i].preinjection_depth_uncertainty = 1.0/sqrt(total(1.0/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2))
			preinjection_chi_sq = total(((boxes[i_intransitboxes[uniq_intransit]].depth[i_duration] - 0.0)/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration])^2)
			preinjection_n_boxes = n_elements(uniq_intransit)
			; check if chi^2 is too high and the uncertainty needs to be rescaled
			if recovered[i].n_boxes gt 1 then begin    
				preinjection_rescaling =  sqrt((preinjection_chi_sq/(preinjection_n_boxes -1) > 1.0))
				recovered[i].preinjection_depth_uncertainty *= preinjection_rescaling
			endif




; 			if keyword_set(display) then begin
; 				for j=0, n_intransitboxes-1 do begin
; 					fit = initialized_fit
; 					boxes[i_intransitboxes[j]] =  fit_box(injected_lc, templates,fit, priors, boxes[i_intransitboxes[j]])
; 				endfor	
; 			endif else begin
				for j=0, n_elements(uniq_intransit)-1 do begin
					fit =spliced_clipped_season_fit; initialized_fit
					boxes[i_intransitboxes[uniq_intransit[j]]] =  fit_box(injected_lc, templates,fit, priors, boxes[i_intransitboxes[uniq_intransit[j]]], demo_plot=demo_plot, i_duration=i_duration)
				endfor	
; 			endelse
; 			for j=0, n_elements(uniq_intransit)-1 do begin
; 					i_flarestonight = where(flares_nights eq boxes_nights[i_intransitboxes[j]], n_flarestonight)
; 					for k=0, n_flarestonight-1 do begin	
; 						fit = initialized_fit
; 						flares[i_flarestonight[k]] = fit_flare(inflated_lc, templates, fit, priors, flares[i_flarestonight[k]])
; 					endfor
; 			endfor
; 			flares_vs_boxes, flares, boxes, inflated_lc, flare_lc=flare_lc, necessary_flares=necessary_flares, templates=templates, fit=fit, priors=priors, i_onflarenight=i_onflarenight, boxeskilledbyflares=boxeskilledbyflares

			box_rednoise_variance = fltarr(n_elements(boxes[0].depth))
	;		for iii=0, n_elements(boxes[0].depth)-1 do begin
				iii = i_duration
				temp_rednoise = -0.1
				converged = 0
				while(~converged) do begin
					temp_rednoise += 0.1		; go a little coarser to speed up simulation
					i_interesting = where(boxes.n[iii] gt 0, n_interesting)
					rednoise_correction = sqrt(1.0 + boxes[i_interesting].n[iii]*temp_rednoise^2);/(1.0 + temp_rednoise^2)
		;  			plothist, boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]/rednoise_correction, bin=0.1, title=temp_rednoise
		;  			oplot_gaussian, bin=0.1, pdf_params=[0,1], boxes[i_interesting].depth[i]/boxes[i_interesting].depth_uncertainty[i]/rednoise_correction
		; 			if question("red noise", /int) then stop
					converged = 1.48*mad(boxes[i_interesting].depth[iii]/boxes[i_interesting].depth_uncertainty[iii]/rednoise_correction) le 1.0 or temp_rednoise gt 2
		
				endwhile
				box_rednoise_variance[iii] = temp_rednoise^2
				boxes[i_interesting].depth_uncertainty[iii] *= rednoise_correction
	;		endfor


			recovered[i].period = injected[i].period
			recovered[i].hjd0 = injected[i].hjd0
			recovered[i].radius = injected[i].radius
			recovered[i].b = injected[i].b

		recovered[i].t23 = injected[i].t23
		recovered[i].t14 = injected[i].t14




			recovered[i].depth = total(boxes[i_intransitboxes[uniq_intransit]].depth[i_duration]/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2)/ total(1.0/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2)
			recovered[i].depth_uncertainty = 1.0/sqrt(total(1.0/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration]^2))
			
			chi_sq = total(((boxes[i_intransitboxes[uniq_intransit]].depth[i_duration] - recovered[i].depth)/boxes[i_intransitboxes[uniq_intransit]].depth_uncertainty[i_duration])^2)
			recovered[i].n_boxes = n_elements(uniq_intransit)
			recovered[i].n_points = total(boxes[i_intransitboxes[uniq_intransit]].n[i_duration], /int)
			; check if chi^2 is too high and the uncertainty needs to be rescaled
			if recovered[i].n_boxes gt 1 then begin    
				recovered[i].rescaling =  sqrt((chi_sq/(recovered[i].n_boxes -1) > 1.0))
				recovered[i].depth_uncertainty *= recovered[i].rescaling
			endif


			recovered[i].n_sigma = recovered[i].depth/recovered[i].depth_uncertainty
			recovered[i].affected_by_flare = total(boxeskilledbyflares[i_intransitboxes[uniq_intransit]])
			if recovered[i].n_points eq 0 then recovered[i].n_sigma =0
			; plot results			
			if keyword_set(display) and keyword_set(not_fake) then begin
				cleanplot, /silent
; 				xplot, 4, xsize=500, ysize=200, title='Red Noise Amplitude'
; 				plot,boxes[0].duration*24, red_variance, psym=-8, xtitle='Duration (hours)', ytitle='Normalized Red Noise', xs=3, thick=3, symsize=2

				cleanplot, /silent
				xplot, 3, title='S/N for "Box" Events', xsize=950, ysize=300
				plot_boxes, boxes, mark=i_intransitboxes[uniq_intransit]
				print, 'injected'
				print_struct, injected[i]
				print, 'recovered'
				print_struct, recovered[i]


			endif

			; if just playing around, then ask if you want to look at fake candidates
			if question('curious', interactive=interactive) or keyword_set(input_injected) then begin
				print, star_dir
				inflated_lc = injected_lc
				target_lc = injected_lc
				save, filename=star_dir + 'inflated_lc.idl', inflated_lc, templates
				save, filename=star_dir + 'box_pdf.idl', boxes,  priors, spliced_clipped_season_fit, box_rednoise_variance
				save, filename=star_dir + 'flares_pdf.idl', flares, flare_lc, necessary_flares, i_onflarenight

				best_candidates = [injected[i], recovered[i]]
				save, filename=star_dir + 'candidates_pdf.idl', best_candidates
				explore_pdf, /fake, 1
			endif
		endif
		if not keyword_set(interactive) and i mod 100 eq 0 then counter, i, n, /timeleft, starttime=starttime, tab_string + tab_string + tab_string+ 'fake #'
	endfor

	
	if ~keyword_set(input_injected) then begin
		save, filename=star_dir + 'injected_and_recovered.idl', injected, recovered
		star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
	endif
END