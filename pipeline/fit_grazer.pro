FUNCTION fit_grazer, lc, templates, fit, priors, grazer

	common mearth_tools
	@filter_parameters
	tonight = round(grazer.hjd-mearth_timezone())
	nights = round(lc.hjd-mearth_timezone())
	i_consider = where(lc.okay and nights eq tonight, N)
	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'SIN*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
;	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
	N_withpriors = N + M
	M_withgrazer = M + 1


	for k=0, n_elements(grazer.duration)-1 do begin
		this_grazer = {hjd0:grazer.hjd, duration:grazer.duration[k]}
		i_ingrazer = where_intransit(lc[i_consider], this_grazer, n_ingrazer)
	
		if n_ingrazer gt 0 then begin
			; set up model
			A = dblarr(N_withpriors, M_withgrazer)
			for i=0, M-1 do A[0:N-1,i] = templates.(i_include[i])[i_consider]/lc[i_consider].fluxerr
			A[i_ingrazer, M_withgrazer-1] = ((1.0 - abs(lc[i_consider[i_ingrazer]].hjd - this_grazer.hjd0)/(this_grazer.duration/2)) > 0)/lc[i_consider[i_ingrazer]].fluxerr
			for i=0, M-1 do A[N+i,i] = 1.0/priors[i_include[i]].uncertainty;templates.(i_include[i])[i_consider]
	
			; setup data + priors
			b = fltarr(N_withpriors)
			b[0:N-1] = lc[i_consider].flux/lc[i_consider].fluxerr
			b[N:*] = priors[i_include].coef/priors[i_include].uncertainty
	
			svdc, A, W, U, V, /double, /column
			coef = dblarr(M_withgrazer)
			variances = dblarr(M_withgrazer)
			singular_limit = 1e-5
			for i=0, M_withgrazer-1 do begin
				if w[i] gt singular_limit then begin
					coef += total(u[*,i]*b)/w[i]*v[*,i]
					variances += (v[*,i]/w[i])^2
		;			fit[i_include[i]].is_needed = 1
				endif else begin
		;		fit[i_include[i]].is_needed = 0
				end
			endfor
			fit[i_include].weight = w[0:M-1]
			fit[i_include].coef = coef[0:M-1]
			fit[i_include].uncertainty = sqrt(variances[0:M-1])
			grazer.depth[k] = coef[M]
			grazer.depth_uncertainty[k] =sqrt(variances[M])
			grazer.n[k] = n_ingrazer
			
	
				model = fltarr(n) 
				for i=0, M-1 do model += coef[i]*templates.(i_include[i])[i_consider]
				model_with_grazer = model
				model_with_grazer += coef[M_withgrazer-1]*A[*, M_withgrazer-1]*lc[i_consider].fluxerr
				residuals = lc[i_consider].flux - model_with_grazer
				chi_sq = total((residuals/lc[i_consider].fluxerr)^2)
				fit[n_elements(fit)-1].coef = sqrt(chi_sq/n) > 1
				fit[n_elements(fit)-1].uncertainty = sqrt(chi_sq/n^2/2.0)
				fit[where(fit.solved)].uncertainty*=fit[n_elements(fit)-1].coef	; make sure this is legit!
				grazer.depth_uncertainty[k]*=fit[n_elements(fit)-1].coef	; make sure this is legit!
		
			if keyword_set(display) and keyword_set(interactive) then begin
				smultiplot, /init, [2,2], colw=[1, .2], xgap=0.01, ygap=0.02
				erase
	
				smultiplot
				loadct, 39, /silent
				@psym_circle
				ploterror, indgen(M), priors[i_include].coef, priors[i_include].uncertainty, charsize=1, xs=7, ys=8, xmargin=[!x.margin[0],100], yrange=[max([priors[i_include].coef+ priors[i_include].uncertainty, fit[i_include].coef+ fit[i_include].uncertainty]), min([priors[i_include].coef-priors[i_include].uncertainty, fit[i_include].coef-fit[i_include].uncertainty])], /nodata, xrange=[-0.5, M+0.1]
				plots, [-.5, M-.5], [0,0], linestyle=2
				oploterror, priors[i_include].coef, priors[i_include].uncertainty, psym=3, thick=2
				xyouts,  indgen(M), priors[i_include].coef,  '!C!C'+priors[i_include].name, orien=90, charsize=1.5, charthick=2, align=0.5
				oploterror, indgen(M) +0.03,  fit[i_include].coef, fit[i_include].uncertainty, color=250, errcolor=250, psym=3, thick=2
				legend, /bottom, /left, color=[0,250], linestyle=[0,0], ['priors', "tonight's fit"], box=0
			
				smultiplot, /dox, /doy
				loadct, 0, /silent
				i_calculated = where(grazer.depth_uncertainty ne 0, complement=i_notyet, n_calculated)
				ploterror, grazer.duration*24, grazer.depth, grazer.depth_uncertainty , /nodata, xs=3, psym=8, charsize=1, yno=0, xmargin=[!x.margin[0],100], xtitle='"grazer" Duration', ytitle='"grazer" Depth', yr=range(grazer.depth, grazer.depth_uncertainty > 0)
				if n_calculated ne n_elements(grazer.duration) then oploterror, grazer.duration[i_notyet]*24, grazer.depth[i_notyet], grazer.depth_uncertainty[i_notyet] 	, color=150, errcolor=150, psym=8
				if n_calculated ge 1 then oploterror, grazer.duration[i_calculated]*24, grazer.depth[i_calculated], grazer.depth_uncertainty[i_calculated], psym=8
				hline, 0, linestyle=2
		
	
				smultiplot
				loadct, 39, /silent
				if n gt 1 then begin
					t = lc[i_consider].hjd -  grazer.hjd
					yrange = [max( lc[i_consider].flux+2*lc[i_consider].fluxerr), min(  lc[i_consider].flux - 2*lc[i_consider].fluxerr)]
					ploterror, 24*t, lc[i_consider].flux, lc[i_consider].fluxerr, psym=8, title='NIGHT'+strcompress(/remo, tonight), xs=3, yrange=yrange, xtitle='Time from Mid-"grazer" (hours)', ytitle='Flux (mag.)', charsize=1
					oplot, 24*t, model, color=250, thick=2, linestyle=2
					fine_t= findgen(301)/300*(max(t) - min(t)) + min(t)
					oplot, 24*fine_t, interpol(model, t, fine_t) +  ((1.0 - abs(fine_t)/(this_grazer.duration/2)) > 0)*grazer.depth[k],  color=250, thick=2
					;oplot, lc[i_consider].hjd, model_with_grazer, color=150
	;				vline, linestyle=2, grazer.hjd-grazer.duration[k]/2.0
	;				vline, linestyle=2, grazer.hjd+grazer.duration[k]/2.0
				endif else plot, [0]
	
	; 		 	rescaling_factor = findgen(1000)/500+.5
	; 		 	loglikelihood = total(-alog(sqrt(2*!pi)*lc.fluxerr)) - N_withpriors*alog(rescaling_factor) - chi_sq/2.0/rescaling_factor^2 
	; 			plot, rescaling_factor, exp(loglikelihood- max(loglikelihood))
	; 		 	loglikelihood = total(-alog(sqrt(2*!pi)*lc.fluxerr)) - N_withpriors*alog(rescaling_factor) - chi_sq/2.0/rescaling_factor^2 - (rescaling_factor-priors[n_elements(fit)-1].coef)^2/2/priors[n_elements(fit)-1].uncertainty^2;
	; 
	; 			plot, rescaling_factor, exp(loglikelihood- max(loglikelihood))
	;			help
	
	
	
	
				smultiplot, /def
			endif
			if (grazer.depth[k]/grazer.depth_uncertainty[k] gt 3 ) then if question('curious?', interactive=interactive) then stop
		endif
	endfor


	return, grazer
; 

END