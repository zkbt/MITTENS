FUNCTION sigma_to_logfap, x, n_eit=n_eit
	if ~keyword_set(n_eit) then n_eit = 1d7
	coefficients_filename = 'convcoefs_for_10_to_the_' + string(alog10(n_eit), format='(F04.1)') + '_eit.idl'
	if file_test(coefficients_filename) eq 0 then begin 
		x = dindgen(1000)/100
		bigG = 0.5 + 0.5d*erf(double(x)/sqrt(2))
		fap = 1.0 - (0.5 + 0.5d*erf(double(x)/sqrt(2)))^n_eit
		logfap = alog(fap)
		logfap_vertices = [-0.1, -0.3, -1, -3, -10]
		nsigma_vertices = interpol(x, logfap, logfap_vertices)
		
		logfap_vertices = [0, logfap_vertices]
		nsigma_vertices = [0, nsigma_vertices]
		
		plot, x, logfap, xtitle='Number of Sigma', ytitle=goodtex('log_{10} FAP'), thick=3
		newx = findgen(1000)/10
		oplot, newx, interpol(logfap_vertices, nsigma_vertices, newx), color=250,thick=3

		save, filename=coefficients_filename, nsigma_vertices, logfap_vertices
	end else restore, coefficients_filename
	
	interpolated_logfap = interpol(logfap_vertices, nsigma_vertices, x)
	return, interpolated_logfap
END



;FUNCTION approxerf, x
;	a = 8*(!pi - 3)/3/!pi/(4-!pi)
;	return, 	sqrt(1.0d - exp(-x^2*(4/!pi + a*x^2)/(1+a*x^2)))
;END
;
;
; = dindgen(1000)/100
;bigG = 0.5 + 0.5d*erf(double(x)/sqrt(2))
;fap = 1.0 - (0.5 + 0.5d*erf(double(x)/sqrt(2)))^n_eit
;
;	if 
;
;
;
;
;threshold = -1.5
;midpoint = interpol(x, logfap, threshold)
;i_plateau = where(logfap ge threshold, n_plateau)
;i_tail = where(logfap lt threshold and finite(logfap), n_plateau)
;
;fit = regress(x[i_tail], logfap[i_tail], yfit=yfit)
;
;model = fltarr(n_elements(x))
;model[i_tail] = yfit
;model[i_plateau] = interpol([0, max(yfit)], [0, min(x[i_tail])], x[i_plateau])
;oplot, color=250, x, model