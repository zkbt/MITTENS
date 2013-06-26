PRO plot_interesting_marples, interesting_marples=interesting_marples, mode

	cleanplot
	if n_elements(interesting_marples) eq 0 then restore, 'population/summary_of_interesting_marples.idl'

		
	if ~keyword_set(mode) then mode = 'signaltonoise'
	case mode of
		'signaltonoise': begin
			x = interesting_marples.depth
			y =  interesting_marples.depth/interesting_marples.depth_uncertainty	
			!x.range=range(x)
			!y.range=range(y);[min(y), 20]
			plot, x, y, psym=3, /xlog, xs=3, ys=3, /ylog, xtitle='Depth (mag.)', ytitle=goodtex('D/\sigma_{MarPLE}')
			d = 10^(findgen(100)/100.0*4 - 3)
			oplot, d, d/0.0005
			oplot, d, d/0.001
			oplot, d, d/0.002
		end		

		'time': begin
			x = interesting_marples.hjd + 2400000.5d
			y =  interesting_marples.depth/interesting_marples.depth_uncertainty	
			!x.range=range(x)
			!y.range=range(y);[min(y), 20]
			plot, x, y, psym=3, xs=3, ys=3, /ylog, xtitle='', xtickunit='Year', ytitle=goodtex('D/\sigma_{MarPLE}')
			d = 10^(findgen(100)/100.0*4 - 3)
		end		

	endcase

END	