PRO plot_xinspect_population, mode, summary_of_candidates=summary_of_candidates, interesting_marples=interesting_marples, ensemble_observation_summary=ensemble_observation_summary, coordinate_conversions=coordinate_conversions, data_click=data_click

	common mearth_tools
	cleanplot

	; load the necessary population summary files
	if n_elements(summary_of_candidates) eq 0 then restore, 'population/summary_of_candidates.idl'
	if n_elements(ensemble_observation_summary) eq 0 then restore, 'population/ensemble_observation_summary.idl'
	if n_elements(interesting_marples) eq 0 then restore, 'population/summary_of_interesting_marples.idl'

	i = where(summary_of_candidates.period lt 10000, n)
	if n eq 0 then begin
		mprint, skipping_string, 'no candidates were found; not plotting anything'
		return
	endif
	
	summary_of_candidates = summary_of_candidates[i]

	if ~keyword_set(mode) then mode = 'candidates_period'
	case mode of
		'candidates_period': begin
			structure = summary_of_candidates
			x = summary_of_candidates.period
			y = summary_of_candidates.depth/summary_of_candidates.depth_uncertainty
			!x.range = (range(x) > 0.1) < 1000
			!y.range = range(y) > 1
			xlog = 1
			ylog = 1
			xtitle='Candidate Period (days)'
			ytitle=goodtex('D/\sigma_{MarPLE}')
		end
	endcase
	plot, x, y, psym=1, symsize=0.5, xs=3, ys=3, xlog=xlog, ylog=ylog, xtitle=xtitle, ytitle=ytitle
	coordinate_conversions = {x:!x, y:!y, p:!p}
	if n_elements(data_click) gt 0 then begin
		normal_points = convert_coord(x, y, /data, /to_normal)
		normal_x = reform(normal_points[0,*])
		normal_y = reform(normal_points[1,*])
		normal_click = convert_coord(data_click.x, data_click.y, /data, /to_normal)
		r = (normal_x - normal_click[0])^2 + (normal_y - normal_click[1])^2

		i_selected = where(r eq min(r))
		@psym_circle
		plots, x[i_selected], y[i_selected], psym=8, symsize=3
		print_struct, structure[i_selected]
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
