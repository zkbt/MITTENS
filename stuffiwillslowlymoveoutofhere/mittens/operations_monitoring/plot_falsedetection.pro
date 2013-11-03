PRO plot_falsedetection, m, overplot=overplot
	n=dindgen(10000)*100
	p_msigma = erf(m/sqrt(2))
	p_false_detection = 1.0 - p_msigma^n
	if keyword_set(overplot) then oplot, n, p_false_detection else plot, n,  p_false_detection, xtitle='Number of Values', ytitle='Probability of False Detection'
END