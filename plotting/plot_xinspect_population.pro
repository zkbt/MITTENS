PRO plot_xinspect_population, input_mo, counter=counter, summary_of_candidates=summary_of_candidates, interesting_marples=interesting_marples, ensemble_observation_summary=ensemble_observation_summary, stellar_sample=stellar_sample, coordinate_conversions=coordinate_conversions, data_click=data_click, selected_object=selected_object, xrange=xrange, yrange=yrange, filtering_parameters=filtering_parameters

	common mearth_tools
	cleanplot
	!p.color = 0
	!p.background = 255
	loadct, 39

	; load the necessary population summary files
	if n_elements(summary_of_candidates) eq 0 then restore, 'population/summary_of_candidates.idl'
	if n_elements(ensemble_observation_summary) eq 0 then restore, 'population/ensemble_observation_summary.idl'
	if n_elements(interesting_marples) eq 0 then restore, 'population/summary_of_interesting_marples.idl'
	if n_elements(stellar_sample) eq 0 then stellar_sample = compile_sample()

	stellar_sample = stellar_sample[sort(stellar_sample.mo)]

	; decide what the mode is going to be
	possible_modes = ['candidates_period', 'candidates_ratio', 'candidates_nboxes', 'marple_hjd', 'marple_depth', 'marple_depthuncertainty', 'marple_npoints', 'sample_radial'] 
	if n_elements(counter) eq 0  then begin
		counter = 0
	endif
	counter = counter mod n_elements(possible_modes)
	mode = possible_modes[counter]

	print, counter, mode
	; if we're dealing with candidates, cull them down and freak out if none exist
	if strmatch(mode, 'candidates*') then begin
		i = where(summary_of_candidates.period lt 10000, n)
		if n eq 0 then begin
			mprint, skipping_string, 'no candidates were found; not plotting anything'
			return
		endif
		summary_of_candidates = summary_of_candidates[i]
		mo_list =  summary_of_candidates.mo
		labels = summary_of_candidates.star_dir
		structure_name = 'candidate'
	endif
	if strmatch(mode, 'marple*') then begin
		mo_list =  interesting_marples.mo
		labels = mo_prefix + mo_list+'/combined/'
		structure_name = 'marple'
		
	endif
	if strmatch(mode, 'sample*') then begin
		mo_list =  stellar_sample.mo
		labels =  mo_prefix + mo_list+'/combined/'
		structure_name = 'star'
	endif



	; set up the plotting variables, depending on the mode
	case mode of
		'candidates_period': begin
			structure = summary_of_candidates
			x = summary_of_candidates.period
			y = summary_of_candidates.depth/summary_of_candidates.depth_uncertainty
			!x.range = (range(x) > 0.01) < 1000
			!y.range = range(y) > 1
			xlog = 1
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Candidate] Period (days)'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'candidates_ratio': begin
			structure = summary_of_candidates
			x = summary_of_candidates.ratio
			y = summary_of_candidates.depth/summary_of_candidates.depth_uncertainty
			!x.range = (range(x) > 0.1) < 1000
			!y.range = range(y) > 1
			xlog = 0
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Candidate] Transit/Anti-Transit (at fixed period)'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'candidates_nboxes': begin
			structure = summary_of_candidates
			x = summary_of_candidates.stats.boxes[0]
			y = summary_of_candidates.depth/summary_of_candidates.depth_uncertainty
			!x.range = range(x) > 0.1
			!y.range = range(y) > 1
			xlog = 1
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Candidate] # of Epochs Covered by Light Curve'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'marple_hjd': begin
			structure = interesting_marples
			x = interesting_marples.hjd + 2400000.5d
			y = interesting_marples.depth/interesting_marples.depth_uncertainty
			!x.range = range(x) > 0.1
			!y.range = range(y) > 1
			xlog = 0
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Individual MarPLE] Epoch'
			ytitle=goodtex('D/\sigma_{MarPLE}')
			xtickunits = 'Time'
		end
		'marple_depth': begin
			structure = interesting_marples
			x = interesting_marples.depth
			y = interesting_marples.depth/interesting_marples.depth_uncertainty
			!x.range = range(x) > 0.0001
			!y.range = range(y) > 1
			xlog = 1
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Individual MarPLE] Depth (mag.)'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'marple_depthuncertainty': begin
			structure = interesting_marples
			x = interesting_marples.depth_uncertainty
			y = interesting_marples.depth/interesting_marples.depth_uncertainty
			!x.range = range(x) > 0.0001
			!y.range = range(y) > 1
			xlog = 1
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle='[Individual MarPLE] Depth Uncertainty (mag.)'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'marple_npoints': begin
			structure = interesting_marples
			x = interesting_marples.n
			y = interesting_marples.depth/interesting_marples.depth_uncertainty
			!x.range = range(x) > 0.1
			!y.range = range(y) > 1
			xlog = 1
			ylog = 0
			xtitle='[Individual MarPLE] # of Observations in Event'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'sample_radial': begin
			structure = stellar_sample
			x = cos(stellar_sample.ra*!PI/180)*stellar_sample.distance
			y = sin(stellar_sample.RA*!pi/180)*stellar_sample.distance
			outer_radius = 33.0
			!x.range = outer_radius*[-1,1]
			!y.range = outer_radius*[-1,1]
			xlog = 0
			ylog = 0
			!x.style=3
			!y.style=3
			xtitle=''
			ytitle=''
			!x.style=7
			!y.style=7
			!x.margin=[2,2]
			!y.margin=[2,2]
		end
	endcase

	; &*!#^&*!^ indices are messed up!!!!
	matched_sample = stellar_sample[value_locate(stellar_sample.mo, structure.mo)]
	if n_elements(filtering_parameters) gt 0 then begin
		ra_hours = matched_sample.ra/15.0
		if filtering_parameters.ra_min gt filtering_parameters.ra_max then begin
			ra_mask = ra_hours ge filtering_parameters.ra_min or ra_hours le filtering_parameters.ra_max
		endif else begin
			ra_mask = ra_hours ge filtering_parameters.ra_min and ra_hours le filtering_parameters.ra_max
		endelse
		dec_mask = matched_sample.dec ge filtering_parameters.dec_min and matched_sample.dec le filtering_parameters.dec_max
		size_mask = matched_sample.radius ge filtering_parameters.size_min and matched_sample.radius le filtering_parameters.size_max
		distance_mask = matched_sample.distance ge filtering_parameters.distance_min and matched_sample.distance le filtering_parameters.distance_max
		i_filter = where(ra_mask and dec_mask and size_mask and distance_mask, n_filter)
	endif else i_filter = lindgen(n_elements(structure))

	x = x[i_filter]
	y = y[i_filter]
	mo_list = mo_list[i_filter]
	labels = labels[i_filter]
	structure = structure[i_filter]
	
	
	; allow for zooming
	if n_elements(xrange) gt 0 then	if xrange[0] ne xrange[1] then !x.range = xrange
	if n_elements(yrange) gt 0 then	if yrange[0] ne yrange[1] then !y.range = yrange


	
	; make an open circle to plot
	theta = findgen(22)/10*!pi
	usersym, cos(theta), sin(theta)

	; plot the window, and save the coordinate conversions
	plot, x, y, psym=1, symsize=0.5, xlog=xlog, ylog=ylog, xtitle=xtitle, ytitle=ytitle, xmargin=xmargin, ymargin=ymargin, xtickunits=xtickunits, title=title
	coordinate_conversions = {x:!x, y:!y, p:!p, xlog:xlog, ylog:ylog}
	; (be careful, the xlog and ylog properties might not persist well if other plots are being drawn before the coordinate_conversions will be needed)

	if mode eq 'sample_radial' then begin
		r = [5, 10, 15, 20, 25]
		gray = 150
		theta = findgen(1000)*!pi*2/999.
		angle = -60*!pi/180
		loadct, file='~/zkb_colors.tbl', 0
		for i=0, n_elements(r)-1 do oplot, cos(theta)*r[i], sin(theta)*r[i], thick=1, color=gray
		off = -1.5
		xyouts, (r-off)*cos(angle), (r-off)*sin(angle), orient=90+angle*180/!pi, rw(r) + ' pc', align=0.5, charsize=2, charthick=1, color=gray
	endif


	; if the density of points on the plot is small enough, print out the LSPM numbers
	i_inplot = where(x gt min(!x.range) and x lt max(!x.range) and y gt min(!y.range) and y lt max(!y.range), n_pointsinplot)
	if n_pointsinplot lt 100 and n_pointsinplot gt 0 then begin
		loadct, 52, file='~/zkb_colors.tbl'

		xyouts, x[i_inplot], y[i_inplot], rw(mo2name(mo_list[i_inplot]))+'!C ', align=0.5, noclip=0, color=127
	endif

	; if plot_xinspect_population has been supplied with a data_click structure, select the closest point in this plot
	if n_elements(data_click) gt 0 then begin
		normal_points = convert_coord(x, y, /data, /to_normal)
		normal_x = reform(normal_points[0,*])
		normal_y = reform(normal_points[1,*])
		normal_click = convert_coord(data_click.x, data_click.y, /data, /to_normal)
		r = (normal_x - normal_click[0])^2 + (normal_y - normal_click[1])^2

		i_selected = where(r eq min(r))
		i_selected = i_selected[0]
		input_mo = mo_list[i_selected]
		print, normal_click
	endif

	if keyword_set(input_mo) then begin
		i_possible = where(mo_list eq input_mo, n_possible)
		if n_possible gt 0 then begin
			loadct, 42, file='~/zkb_colors.tbl'
			
			plots, x[i_possible], y[i_possible], psym=8, symsize=1.5, thick=1, color=100
		
			if n_elements(i_selected) eq 0 then begin
				highest = where(y[i_possible] eq max(y[i_possible]), n_high)
				if n_high gt 0 then i_selected = i_possible[highest[0]]
			endif
		endif
	endif
	
	; if one of the objects has been selected, mark it
	if n_elements(i_selected) gt 0 then begin
		loadct, 42, file='~/zkb_colors.tbl'
		theta = findgen(21)/20*2*!pi
		usersym, cos(theta), sin(theta), thick=3
		plots, x[i_selected], y[i_selected], psym=8, symsize=3, color=0, thick=3
		usersym, cos(theta), sin(theta), thick=1
		
		selected_object = create_struct('mo', mo_list[i_selected], 'star_dir', labels[i_selected], structure_name, structure[i_selected])
		text =   '  '+ mo2name(selected_object.mo) + '  ' ; selected_object.star_dir

		normal_select = convert_coord(x[i_selected], y[i_selected], /data, /to_normal)
		floating_xyouts, x[i_selected], y[i_selected], text, align=normal_select[0] gt 0.5, charsize=2, charthick=2


		help, /st, selected_object
	endif
; 
; 	case mode of
; 		'signaltonoise': begin
; 			x = summary_of_candidates.depth
; 			y =  summary_of_candidates.depth/summary_of_candidates.depth_uncertainty	
; 			!x.range=range(x) > 0.0001
; 			!y.range=range(y) > 1;[min(y), 20]
; 			plot, x, y, psym=3, /xlog, xs=3, ys=3, /ylog, xtitle='Depth (mag.)', ytitle=goodtex('D/\sigma_{MarPLE}')
; 			d = 10^(findgen(100)/100.0*4 - 3)
; 			xyouts, x, y, rw(summary_of_candidates.ls)
; 			oplot, d, d/0.0005
; 			oplot, d, d/0.001
; 			oplot, d, d/0.002
; 		end		
; 
; 		'period': begin
; 			x = summary_of_candidates.period
; 			y =  summary_of_candidates.depth/summary_of_candidates.depth_uncertainty	
; 			!x.range=range(x) > 0.0001
; 			!y.range=range(y) > 1;[min(y), 20]
; 			plot, x, y, psym=3, xs=3, ys=3, /ylog, xtitle='Period (days)', ytitle=goodtex('D/\sigma_{MarPLE}'), /xlog
; 			d = 10^(findgen(100)/100.0*4 - 3)
; ; 		end		
; 
; 	endcase
END
