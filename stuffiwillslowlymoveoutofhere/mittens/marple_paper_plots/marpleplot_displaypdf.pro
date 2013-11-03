PRO marpleplot_displaypdf, eps=eps, tall=tall, kludge=k, xrange=xrange, t_xrange=t_xrange, p_xrange=p_xrange, e_xrange=e_xrange


	common mearth_tools
	common this_star

	filename = 'marpleplot_injection.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		if keyword_set(tall) then device, filename=filename, /encap, xsize=7.5, ysize=7.5, /inches, /color else device, filename=filename, /encap, xsize=7.5, ysize=4, /inches, /color
	endif
	cleanplot
	charsize = 0.6
	!p.charsize=charsize
	!y.margin=[35,5]
	!x.margin=[12,3]
	symsize = 0.3
	restore, star_dir() + 'box_pdf.idl'
	restore, star_dir() + 'cleaned_lc.idl'
	plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=candidate, /externalform
	@planet_constants
	if strmatch(star_dir, '*fake*') gt 0 then begin
		restore, star_dir + 'injected_and_recovered.idl'	
		this_fake = where(injected.period eq candidate.period and injected.hjd0 eq candidate.hjd0, n_this)
		if n_this eq 1 then 	fake = injected[this_fake] else print, 'COULD NOT FIND THE FAKE!'
		i_rescale = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_rescale)
		if n_rescale gt 0 then fake.n_sigma /= priors[i_rescale].coef else stop
	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)	

		inject_str = '!CInjected a ' + $
				rw(string(fake.radius, form='(F5.1)')) + goodtex('R_{!20S!3}') + ', ' + $
				'P='+ rw(string(candidate.period, form='(F5.2)')) + ' day, ' + $
				'b=' + rw(string(format='(F3.1)', fake.b)) +$
				' planet at "' + rw(string(form='(F4.1)', fake.n_sigma)) + goodtex('\sigma') +'"'+$
				' into a '+string(form='(F4.2)', lspm_info.radius) + goodtex('R_{!9n!3}') + ' star with '+ rw(string(form='(I2)', mean(sqrt(box_rednoise_variance[i_duration]))*100)) + '% red noise; !C'
		recover_str = '!C!Crecovered it as a '+rw(string(form='(F5.1)', lspm_info.radius*r_sun*sqrt(1-10^(-0.4*candidate.depth))/r_earth)) + goodtex('R_{!20S!3}') +$
			' candidate at '  + rw(string(form='(F4.1)', candidate.depth/candidate.depth_uncertainty)) + goodtex('\sigma') + ' with MISS MarPLE'
		xyouts, align=0.5, /norm, 0.5, 0.99, inject_str, charsize=1.5*charsize, charthick=1.5
		xyouts, align=0.5, /norm, 0.5, 0.99, recover_str, charsize=1.7*charsize, charthick=3
	endif else radius_string = ''
	!y.margin = [5,19]
	!p.charsize = charsize

	n_panels = 6
	total_width = 130
	width = total_width/n_panels
	left_side = 12
	panels = [[left_side + indgen(n_panels)*width],[ total_width - width*indgen(n_panels) - width]]








	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)	
	i_interesting = where(boxes.n[i_duration] gt 0)
	i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidate, i_oot=i_oot,  /box, n_intransit)];buffer=-candidate.duration/4,
	pad = long((max(boxes.hjd) - min(boxes.hjd))/candidate.period)+1

	nights = round(boxes.hjd - mearth_timezone())
	phased_time = (boxes.hjd - candidate.hjd0)/candidate.period + pad + 0.5
	orbit_number = long(phased_time)
	phased_time = (phased_time - orbit_number - 0.5)*candidate.period

	i_intransit = i_intransit[sort(abs(phased_time[i_intransit]))]
	h = histogram(nights[i_intransit], reverse_indices=ri)
	ri_firsts = ri[uniq(ri[0:n_elements(h)-1])]
	uniq_intransit =(ri[ri_firsts])
	events = round((boxes[i_intransit].hjd - candidate.hjd0)/candidate.period)
	uniq_events = events[uniq_intransit]


;	if keyword_set(t_xrange) then xrange = t_xrange else xrange = range(cleaned_lc.hjd+2400000.5d)

	event_width = 11
	for i_event = 0, n_elements(uniq_events)-1 < 2 do begin
		box = {hjd:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n:0}
		box_number = uniq_events[i_event]
		box.hjd = candidate.hjd0 + box_number*candidate.period
		box.duration = candidate.duration
		box.depth = candidate.depth
		i_this =i_intransit[uniq_intransit[i_event]]
		box.n = boxes[i_this].n[i_duration]
		box.depth = boxes[i_this].depth[i_duration]
		box.depth_uncertainty = boxes[i_this].depth_uncertainty[i_duration]
		if i_event eq 1 then replace = '<------ Light Curves of Lone Eclipses ------>' else replace = ' ' 
		lc_plot, /fake, /time, box=box, xmargin=panels[i_event,*], ymargin=!y.margin, /event, /anon, /externalform, charsize=charsize, symsize=symsize, /noright, noleft=i_event ne 0, replace=replace , noxtitle=i_event ne 1, addspace='                      ', offset=min(uniq_events), xrange=e_xrange

	endfor

	if ~keyword_set(t_xrange) then t_xrange = range(cleaned_lc.hjd+2400000.5d)
	lc_plot, /fake,  /anon, /time, /externalform, ymargin=!y.margin, xmargin = panels[4,*], charsize=charsize, symsize=symsize, /noright, /noleft, xrange=t_xrange, replace='Linear in Time'
	lc_plot,  /fake, /anon, /externalform, ymargin=!y.margin, xmargin = panels[5,*], charsize=charsize, symsize=symsize, /noleft,replacementtitle='Linear in Obs.'
	lc_plot,  /fake, /anon, /time, /phased, /externalform, ymargin=!y.margin, xmargin = panels[3,*], charsize=charsize, symsize=symsize, /noleft, replacementtitle='Phased' , /noright, /noxtit, xrange=p_xrange


	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
END