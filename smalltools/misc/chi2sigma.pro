FUNCTION chi2sigma, v, df
	sigma = dindgen(1000)/100
	prob = 1.0 - erf(sigma/sqrt(2))
	chiprob = 1.0 -chisqr_pdf(double(v), df)
;	chiprobgrid = 1.0 - chisqr_pdf(double(sigma^2), df)
	intersect = interpol(sigma, prob, chiprob) 
	!y.margin=[5,5]
	plot, sigma, prob, /ylog, title=string(v, format='(F10.2)') + ' for ' + strcompress(/remove, df) + ' d. o. f. = ' + string(intersect, format='(F5.2)') + goodtex('\sigma') + '!C', xtitle=goodtex('\sigma'), ytitle='FAP', charsize=2
;	oplot, linestyle=1, sigma, chiprobgrid
;	axis, xaxis=1, xtickv=xtickget, xtickn=
	hline, chiprob
	vline, intersect
	cleanplot
	return, intersect
END