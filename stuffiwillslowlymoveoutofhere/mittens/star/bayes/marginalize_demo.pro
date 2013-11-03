FUNCTION generate_fake
	;common mearth_tools
	f = {fake}
	radii = [2.5]
	min_period = 5
	max_period = 10.0
	f.period = randomu(seed)*(max_period - min_period) + min_period
	f.hjd0 = randomu(seed)*f.period + 55000.0d
	f.radius = radii[randomu(seed)*n_elements(radii)]
	f.b = randomu(seed)
	return, f
END

PRO marginalize_demo, n, profile=profile, demo_plot=demo_plot, remake=remake
	cleanplot
  !y.margin=[5,10]
  demo_plot = 1
	; diagnose the slow bits (probably occultnl)
	if keyword_set(profile) then begin
		profiler, /reset
		profiler, /system
		profiler
		fake_pdfs, n
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
	really_star_dir = star_dir

	;if is_uptodate( star_dir + fake_dir + 'ext_var.idl',  star_dir + 'ext_var.idl') eq 0 then lc_to_pdf, /re

cleanplot
	; setup fake directory
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

	boxes = boxes[where(total(boxes.n, 1) gt 0)]
	p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
	pad = long((max(boxes.hjd) - min(boxes.hjd))/p_min)+1

	print, display

 	boxes_nights = long(boxes.hjd -mearth_timezone())
	flares_nights = long(flares.hjd -mearth_timezone())
	initial_boxes = boxes
	initial_flares = flares
	lc = inflated_lc
	struct = {period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_sigma:0.0, b:0.0, radius:0.0, n_boxes:0, n_points:0, affected_by_flare:0, n_sigma_bestevent:0.0}
	injected = replicate(struct, n)
	recovered = replicate(struct, n)
	n_data = n_elements(lc)
	star_dir = star_dir + fake_dir
	planet_stri = ''
	star_dir = ''
	for i=0L, n-1 do begin 
		; inject the transit
		copy_struct, generate_fake(), struct
		injected[i] = struct
		a_over_rs = a_over_rs(lspm_info.mass, lspm_info.radius, injected[i].period)
		injected[i].depth = (injected[i].radius*0.00917/lspm_info.radius)^2; (injected[i].radius*r_earth/r_sun/lspm_info.radius)^2
		rp_over_rs = sqrt(injected[i].depth)
		injected[i].duration = (injected[i].period/!pi*asin(sqrt((1+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))
	;	injected[i].duration = (injected[i].period/!pi*asin(sqrt((1+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2))); + injected[i].period/!pi*asin(sqrt((1-rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2)))/2
		i_intransit = where_intransit(lc, injected[i], i_oot=i_oot, n_intransit)
		injected[i].n_points = n_intransit
		transit = fltarr(n_data)
		if n_intransit gt 0 then begin
			sinphi = sin(!pi*injected[i].duration/injected[i].period)
			inclination = acos(sqrt(((1.0 + injected[i].radius*r_earth/lspm_info.radius/r_sun)^2/a_over_rs^2 - sinphi^2)/(1.0 - sinphi^2)))
			transit = -2.5*alog10( zeroeccmodel(lc.hjd,injected[i].hjd0,injected[i].period,lspm_info.mass,lspm_info.radius,injected[i].radius*r_earth/r_sun,inclination,0.0,0.24,0.38) )
		;	print, i, injected[i].period,lspm_info.mass,lspm_info.radius,injected[i].radius*r_earth/r_sun,inclination,0.0,0.24,0.38, injected[i].b
;			transit[i_intransit] += injected[i].depth
			transit_numbers = (lc[i_intransit].hjd - injected[i].hjd0)/injected[i].period
			uniq_transits = uniq(round(transit_numbers), sort(transit_numbers))
			injected[i].n_boxes = n_elements(uniq_transits)
			injected[i].depth_uncertainty = sqrt(1.0/total(1.0/lc[i_intransit].fluxerr^2))
			injected[i].n_sigma = injected[i].depth/injected[i].depth_uncertainty

      star_stri = 'MEarth Target Star = '+ stregex(/ext, really_star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')+' = (M'+string(format='(I1)', lspm_info.sp)+', '+string(format='(F4.2)', lspm_info.radius) + ' Solar radii)'
      planet_stri = 'Planet = (' + string(format='(F3.1)', injected[i].radius) + ' Earth radii, '+strcompress(/remo, string(format='(F4.1)', injected[i].period)) + ' days, b = ' + string(format='(F4.2)', injected[i].b)  +')'
	!y.margin=[4,5]
		endif
		injected_lc = lc
		injected_lc.flux += transit		

			recovered[i].duration =  ((injected[i].period/!pi*asin(sqrt((1-rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2))) + (injected[i].period/!pi*asin(sqrt((1+rp_over_rs)^2 - injected[i].b^2)/sqrt(a_over_rs^2 - injected[i].b^2))))/2
			duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
			i_duration = value_locate(boxes[0].duration-duration_bin/2, recovered[i].duration) > 0
;			recovered[i].duration = boxes[0].duration[i_duration]

		; fit the in-transit boxes
		boxes = initial_boxes
		i_intransitboxes = where_intransit(boxes, injected[i], n_intransitboxes, buffer=-injected[i].duration/4)
		flares = initial_flares
		if n_intransitboxes gt 0 and n_intransit gt 0 then begin




			phased_time = (boxes.hjd - injected[i].hjd0)/injected[i].period + pad + 0.5
			orbit_number = long(phased_time)
			phased_time = (phased_time - orbit_number - 0.5)*injected[i].period

			i_intransitboxes = i_intransitboxes[sort(abs(phased_time[i_intransitboxes]))]
			h = histogram(boxes_nights[i_intransitboxes], reverse_indices=ri)
			ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
			uniq_intransit =(ri[ri_firsts])


; 				for j=0, n_elements(uniq_intransit)-1 do begin
; 					fit =spliced_clipped_season_fit; initialized_fit
; 					boxes[i_intransitboxes[uniq_intransit[j]]] =  fit_box(injected_lc, templates,fit, priors, boxes[i_intransitboxes[uniq_intransit[j]]], demo_plot=demo_plot, i_duration=i_duration)
; 				endfor	


				for j=0, n_elements(uniq_intransit)-1 do begin
					fit =spliced_clipped_season_fit; initialized_fit
				;	boxes[i_intransitboxes[uniq_intransit[j]]]
					temp =  fit_box(injected_lc, templates,fit, priors, boxes[i_intransitboxes[uniq_intransit[j]]], demo_plot=demo_plot, do_eps=do_eps, stri=planet_stri+'!C'+star_stri,  i_duration=i_duration)
    ;      if keyword_set(do_eps) then           temp =  fit_box(inflated_lc, templates,fit, priors, boxes[i_intransitboxes[uniq_intransit[j]]], demo_plot=demo_plot, do_eps=do_eps, i_duration=i_duration, /no_box, stri=star_stri)
				endfor	


	endif
endfor
	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')

END
