FUNCTION say_occurrence_rate, integral, n_det
	f_grid = findgen(10000)/5000
	dnexpected = mean(f_grid[1:*] - f_grid)*integral
	cleanplot
	xplot
	
	prob =  (f_grid*integral)^n_det*exp(-f_grid*integral)/gamma(n_det+1)
	cum_prob = total(/cum, dnexpected*prob)
	plot, f_grid, prob, yr=[0,1], linestyle=1
	oplot, f_grid, cum_prob
	f_peak = n_det/integral
	plots, f_peak, interpol(prob, f_grid, f_peak), psym=4, symsize=3
	xyouts, f_peak, interpol(prob, f_grid, f_peak), f_peak
	lines =  [0.682689 , 0.954500, 0.997300 ]

	vline,  interpol(f_grid, cum_prob, lines)
	xyouts,  interpol(f_grid, cum_prob, lines), 1, lines, orient=-90
	print, 'the expected # of planets MEarth should find for an occurrence rate of unity is ', string(format='(F6.2)', integral)

		print, 'having found ',strcompress(n_det, /remo),', MEarth says upper limts on the occurence are '
		print, 'f < ', string(format='(F5.3)',interpol(f_grid, cum_prob, lines))
		print, ' with confidences of '
		print, '     ', string(format='(F5.3)',lines)
		print
	if n_det gt 0 then  begin
		onesig = [0.15865, 0.5, 0.8413]
		print, 'and the estimate of the occurrence rate is'
		med = interpol(f_grid, cum_prob, 0.5)
		lower_err = interpol(f_grid, cum_prob, 0.5) - interpol(f_grid, cum_prob, 0.15865) 
		upper_err =interpol(f_grid, cum_prob,  0.8413) -  interpol(f_grid, cum_prob, 0.5) 
		print, 'f = ', string(format='(F5.3)',med), ', -', string(format='(F5.3)',lower_err), ', +', string(format='(F5.3)',upper_err), ' (1 sigma)'
		statement = '     f = ' + string(format='(F5.3)',med)+ '_{-'+ string(format='(F5.3)',lower_err) +'}^{+'+ string(format='(F5.3)',upper_err)+'}' 
		statement +=  '!C!C     f > ' + string(interpol(f_grid, cum_prob, 0.05), format='(F5.3)') +' (95% conf.; 1-sided)'
		statement +=  '!C!C     f < ' + string(interpol(f_grid, cum_prob, 0.95), format='(F5.3)') +' (95% conf.; 1-sided)'
		return, goodtex(statement)
	endif else begin
		statement = '     f < ' + string(interpol(f_grid, cum_prob, 0.6826), format='(F5.3)') + ' (68% conf.; 1-sided)'
		statement += '!C!C' + '     f < ' + string(interpol(f_grid, cum_prob, 0.954), format='(F5.3)') +' (95% conf.; 1-sided)'
		return,  goodtex(statement)
	endelse
END