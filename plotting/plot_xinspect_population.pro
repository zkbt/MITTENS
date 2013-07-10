PRO plot_xinspect_population, counter=counter, summary_of_candidates=summary_of_candidates, interesting_marples=interesting_marples, ensemble_observation_summary=ensemble_observation_summary, stellar_sample=stellar_sample, coordinate_conversions=coordinate_conversions, data_click=data_click, selected_object=selected_object

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
		lspmnumbers =  summary_of_candidates.ls
		labels = summary_of_candidates.star_dir
		structure_name = 'candidate'
	endif
	if strmatch(mode, 'marple*') then begin
		lspmnumbers =  interesting_marples.lspmn
		labels = 'ls'+string(lspmnumbers, form='(I04)')+'/combined/'
		structure_name = 'marple'
	endif
	if strmatch(mode, 'sample*') then begin
		lspmnumbers =  stellar_sample.lspmn
		labels = 'ls'+string(lspmnumbers, form='(I04)')+'/combined/'
		structure_name = 'star'
	endif

; 

	; set up the plotting variables, depending on the mode
	case mode of
		'candidates_period': begin
			structure = summary_of_candidates
			x = summary_of_candidates.period
			y = summary_of_candidates.depth/summary_of_candidates.depth_uncertainty
			!x.range = (range(x) > 0.01) < 1000
			!y.range = range(y) > 1
			xlog = 1
			ylog = 1
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
			xlog = 1
			ylog = 1
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
			ylog = 1
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
			ylog = 1
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
			ylog = 1
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
			ylog = 1
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
			ylog = 1
			xtitle='[Individual MarPLE] # of Observations in Event'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
		'sample_radial': begin
			structure = stellar_sample
			x = cos(stellar_sample.ra)*stellar_sample.distance
			y = sin(stellar_sample.ra)*stellar_sample.distance
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
			xmargin=[2,2]
			ymargin=[2,2]
		end
	endcase




	
	; make an open circle to plot
	theta = findgen(22)/10*!pi
	usersym, cos(theta), sin(theta)

	; plot the window, and save the coordinate conversions
	plot, x, y, psym=1, symsize=0.5, xlog=xlog, ylog=ylog, xtitle=xtitle, ytitle=ytitle, xmargin=xmargin, ymargin=ymargin, xtickunits=xtickunits, title=title
	coordinate_conversions = {x:!x, y:!y, p:!p, xlog:xlog, ylog:ylog}
	; (be careful, the xlog and ylog properties might not persist well if other plots are being drawn before the coordinate_conversions will be needed)

	; if plot_xinspect_population has been supplied with a data_click structure, select the closest point in this plot
	if n_elements(data_click) gt 0 then begin
		normal_points = convert_coord(x, y, /data, /to_normal)
		normal_x = reform(normal_points[0,*])
		normal_y = reform(normal_points[1,*])
		normal_click = convert_coord(data_click.x, data_click.y, /data, /to_normal)
		r = (normal_x - normal_click[0])^2 + (normal_y - normal_click[1])^2

		i_selected = where(r eq min(r))
		i_selected = i_selected[0]

		print, normal_click
	endif

	; if one of the objects has been selected, mark it
	if n_elements(i_selected) gt 0 then begin
		plots, x[i_selected], y[i_selected], psym=8, symsize=3, color=254
		
		selected_object = create_struct('lspmn', lspmnumbers[i_selected], 'star_dir', labels[i_selected], structure_name, structure[i_selected])
		text =   '  LSPM'+string(form='(I04)', selected_object.lspmn) + '  ' ; selected_object.star_dir

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
