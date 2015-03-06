FUNCTION fit_flare, lc, templates, fit, priors, flare, i_decay=i_decay

	common mearth_tools
	@filter_parameters
	tonight = round(flare.hjd-mearth_timezone())
	nights = round(lc.hjd-mearth_timezone())
	i_consider = where(lc.okay and nights eq tonight, N)
;	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'SIN*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
	N_withpriors = N + M
	M_withflare = M + 1

	i_seasonwide_rescaling = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_seasonwidematch)
	if n_seasonwidematch eq 1 then seasonwide_rescaling = priors[i_seasonwide_rescaling].coef

	for k=0, n_elements(flare.decay_time)-1 do begin
		if keyword_set(i_decay) then if k ne round(i_decay) then continue
		this_flare = {hjd:flare.hjd, decay_time:flare.decay_time[k]}
		i_inflare = where(lc[i_consider].hjd ge this_flare.hjd, n_inflare);where_inflare(lc[i_consider], this_flare, n_inflare)
	
		if n_inflare gt 0 then begin

			; loop until rescaling converges
			rescaling = 1.0
			converged = 0
			count  =0
			while(~converged) do begin
				previous_rescaling = rescaling
				; set up model
				A = dblarr(N_withpriors, M_withflare)
				for i=0, M-1 do A[0:N-1,i] = templates.(i_include[i])[i_consider]/lc[i_consider].fluxerr/rescaling
				A[i_inflare, M_withflare-1] = exp(-(lc[i_consider[i_inflare]].hjd - this_flare.hjd)/this_flare.decay_time)/lc[i_consider[i_inflare]].fluxerr/rescaling
				for i=0, M-1 do A[N+i,i] = 1.0/priors[i_include[i]].uncertainty;templates.(i_include[i])[i_consider]
		
				; setup data + priors
				b = fltarr(N_withpriors)
				b[0:N-1] = lc[i_consider].flux/lc[i_consider].fluxerr/rescaling
				b[N:*] = priors[i_include].coef/priors[i_include].uncertainty
		
				svdc, A, W, U, V, /double, /column
				coef = dblarr(M_withflare)
				variances = dblarr(M_withflare)
				singular_limit = 1e-5
				for i=0, M_withflare-1 do begin
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
				flare.height[k] = coef[M]
				flare.height_uncertainty[k] =sqrt(variances[M])
				flare.n[k] =total( exp(-(lc[i_consider[i_inflare]].hjd - this_flare.hjd)/this_flare.decay_time))
	
				model = fltarr(n) 
				for i=0, M-1 do model += coef[i]*templates.(i_include[i])[i_consider]
				model_with_flare = model
				model_with_flare += coef[M_withflare-1]*A[*, M_withflare-1]*lc[i_consider].fluxerr*rescaling
				residuals = lc[i_consider].flux - model_with_flare
				deviates_from_prior = (fit[i_include].coef - priors[i_include].coef)/priors[i_include].uncertainty
		;		print, residuals_from_prior
				chi_sq = total((residuals/lc.fluxerr)^2);+ total(deviates_from_prior^2)


				rescaling = sqrt((chi_sq + seasonwide_rescaling^2*n_effective_for_rescaling)/(n + n_effective_for_rescaling)) > 1; sqrt(chi_sq/n) > 1
;				print, string(format='(F5.2)', previous_rescaling),  ' --> ',  string(format='(F5.2)',rescaling)

				converged = abs((rescaling - previous_rescaling)/rescaling) lt 0.01 or count gt 5
				count +=1
	
				fit[n_elements(fit)-1].coef = rescaling
				fit[n_elements(fit)-1].uncertainty = sqrt(chi_sq/n^2/2.0)

				flare.rescaling[k] = rescaling

; ; ; ; 				print, 'n = ', n, ', m = ', m
; ; ; ; 				print, 'chi_sq = ', total((residuals/lc.fluxerr)^2), ', chi_prior =', + total(deviates_from_prior^2)
; ; ; 			;	plot, rescaling_factor, exp(loglikelihood- max(loglikelihood))
; ; ; 				fit[n_elements(fit)-1].coef = sqrt(chi_sq/n) > 1
; ; ; 				fit[n_elements(fit)-1].uncertainty = sqrt(chi_sq/n^2/2.0)
; ; ; 				fit[where(fit.solved)].uncertainty*=fit[n_elements(fit)-1].coef	; make sure this is legit!
; ; 				flare.height_uncertainty[k]*=fit[n_elements(fit)-1].coef	; make sure this is legit!
; 				flare.rescaling[k] = sqrt(chi_sq/n) > 1
			endwhile
		
			if keyword_set(display) and keyword_set(interactive) and (flare.height[k]/flare.height_uncertainty[k] lt -3 ) and keyword_set(not_fake) then begin

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
				al_legend, /bottom, /left, color=[0,250], linestyle=[0,0], ['priors', "tonight's fit"], box=0
			
				smultiplot, /dox, /doy
				loadct, 0, /silent
				i_calculated = where(flare.height_uncertainty ne 0, complement=i_notyet, n_calculated)
				ploterror, flare.decay_time*24, flare.height, flare.height_uncertainty , /nodata, xs=3, psym=8, charsize=1, yno=0, xmargin=[!x.margin[0],100], xtitle='"flare" decay_time', ytitle='"flare" height', yr=reverse(range(flare.height, flare.height_uncertainty > 0))
				if n_calculated ne n_elements(flare.decay_time) then oploterror, flare.decay_time[i_notyet]*24, flare.height[i_notyet], flare.height_uncertainty[i_notyet] 	, color=150, errcolor=150, psym=8
				if n_calculated ge 1 then oploterror, flare.decay_time[i_calculated]*24, flare.height[i_calculated], flare.height_uncertainty[i_calculated], psym=8
				hline, 0, linestyle=2
		
	
				smultiplot
				loadct, 39, /silent
				if n gt 1 then begin 
					t = lc[i_consider].hjd -  flare.hjd
					yrange = [max( lc[i_consider].flux+2*lc[i_consider].fluxerr), min(  lc[i_consider].flux - 2*lc[i_consider].fluxerr)]
					ploterror, 24*t, lc[i_consider].flux, lc[i_consider].fluxerr, psym=8, title='NIGHT'+strcompress(/remo, tonight), xs=3, yrange=yrange, xtitle='Time from Mid-"flare" (hours)', ytitle='Flux (mag.)', charsize=1
					oplot, 24*t, model, color=250, thick=2, linestyle=2
					fine_t= findgen(301)/300*(max(t) - min(t))*1.1 + min(t)
					;oplot, 24*fine_t, interpol(model, t, fine_t) + (abs(fine_t)  lt flare.decay_time[k]/2)*flare.height[k],  color=250, thick=2
					oplot, 24*fine_t, interpol(model, t, fine_t) + exp(-(fine_t)/this_flare.decay_time)*flare.height[k]*(fine_t gt 0), color=250, thick=2
				endif else plot, [0]
				smultiplot, /def
 				if question('curious?', interactive=interactive) then stop
			endif
		endif
	endfor


	return, flare
END