PRO plot_candidates, summary_of_candidates, mode=mode

	common mearth_tools
	cleanplot
	if n_elements(summary_of_candidates) eq 0 then restore, 'population/summary_of_candidates.idl'

	i = where(summary_of_candidates.period lt 10000, n)
	if n eq 0 then begin
		mprint, skipping_string, 'no candidates were found; not plotting anything'
		return
	endif
	
	summary_of_candidates = summary_of_candidates[i]

	if ~keyword_set(mode) then mode = 'signaltonoise'
	case mode of
		'signaltonoise': begin
			x = summary_of_candidates.depth
			y =  summary_of_candidates.depth/summary_of_candidates.depth_uncertainty	
			!x.range=range(x) > 0.0001
			!y.range=range(y) > 1;[min(y), 20]
			plot, x, y, psym=3, /xlog, xs=3, ys=3, /ylog, xtitle='Depth (mag.)', ytitle=goodtex('D/\sigma_{MarPLE}')
			d = 10^(findgen(100)/100.0*4 - 3)
			xyouts, x, y, rw(summary_of_candidates.ls)
			oplot, d, d/0.0005
			oplot, d, d/0.001
			oplot, d, d/0.002
		end		

		'period': begin
			x = summary_of_candidates.period
			y =  summary_of_candidates.depth/summary_of_candidates.depth_uncertainty	
			!x.range=range(x) > 0.0001
			!y.range=range(y) > 1;[min(y), 20]
			plot, x, y, psym=3, xs=3, ys=3, /ylog, xtitle='Period (days)', ytitle=goodtex('D/\sigma_{MarPLE}'), /xlog
			d = 10^(findgen(100)/100.0*4 - 3)
		end		

	endcase
END
