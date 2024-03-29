FUNCTION fit_box, lc, templates, fit, priors, box, i_duration=i_duration, variability_model=variability_model, systematics_model=systematics_model, demo_plot=demo_plot, do_eps=do_eps, stri=stri, no_box=no_box, uncertainty_overall_model=uncertainty_overall_model, uncertainty_variability_model=uncertainty_variability_model

	common mearth_tools
	@filter_parameters

	; figure out what night tonight is
	tonight = round(box.hjd-mearth_timezone())
	nights = round(lc.hjd-mearth_timezone())

	; data points to consider in the fit
	i_consider = where(lc.okay and nights eq tonight, N)
	; data points on this night (even if not good)
	i_tonight =  where(nights eq tonight, N_tonight)
;	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)
	; include parameters that need to be solved, systematics or sin or cos or nights
	i_include = where(fit.solved and (fit.is_variability eq 0 or strmatch(fit.name, 'SIN*') eq 1 or strmatch(fit.name, 'COS*') eq 1 or strmatch(fit.name, 'NIGHT'+strcompress(/remo, tonight)) eq 1), M)

	; number of "data points" and parameters (including box)
	N_withpriors = N + M
	M_withbox = M + 1

	i_seasonwide_rescaling = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_seasonwidematch)
	if n_seasonwidematch eq 1 then seasonwide_rescaling = priors[i_seasonwide_rescaling].coef

	; loop over grid of possible transit durations
	for k=0, n_elements(box.duration)-1 do begin
		if n_elements(i_duration) eq 1 then if k ne i_duration then continue
		this_box = {hjd0:box.hjd, duration:box.duration[k]}
		i_inbox = where_intransit(lc[i_consider], this_box, n_inbox)

		if n_inbox gt 0 then begin

			; loop until rescaling converges
			rescaling = 1.0
			converged = 0
			count  = 0
			while(~converged) do begin
				previous_rescaling = rescaling
	
				; set up model
				A = dblarr(N_withpriors, M_withbox)
				for i=0, M-1 do A[0:N-1,i] = templates.(i_include[i])[i_consider]/lc[i_consider].fluxerr/rescaling
				A[i_inbox, M_withbox-1] = 1.0/lc[i_consider[i_inbox]].fluxerr/rescaling
				for i=0, M-1 do A[N+i,i] = 1.0/priors[i_include[i]].uncertainty;templates.(i_include[i])[i_consider]
		
				; setup data + priors
				b = fltarr(N_withpriors)
				b[0:N-1] = lc[i_consider].flux/lc[i_consider].fluxerr/rescaling
				b[N:*] = priors[i_include].coef/priors[i_include].uncertainty
	
				; do fit, ignore singular values
				svdc, A, W, U, V, /double, /column
				coef = dblarr(M_withbox)
				variances = dblarr(M_withbox)
				if keyword_set(demo_plot) or n_elements(uncertainty_overall_model) gt 0 then covariances = dblarr(M_withbox,M_withbox)
				singular_limit = 1e-5
				for i=0, M_withbox-1 do begin
					if w[i] gt singular_limit then begin
						coef += total(u[*,i]*b)/w[i]*v[*,i]
						variances += (v[*,i]/w[i])^2
						if keyword_set(demo_plot) or n_elements(uncertainty_overall_model) gt 0 then for k_demo=0, M-1 do covariances[*,k_demo] +=(v[*,i]*v[k_demo,i]/w[i]^2)
			;			fit[i_include[i]].is_needed = 1
					endif else begin
			;		fit[i_include[i]].is_needed = 0
					end
				endfor
	
				; assign coefficients
				fit[i_include].weight = w[0:M-1]
				fit[i_include].coef = coef[0:M-1]
				fit[i_include].uncertainty = sqrt(variances[0:M-1])
				box.depth[k] = coef[M]
				box.depth_uncertainty[k] =sqrt(variances[M])
				box.n[k] = n_inbox
				
				model = fltarr(n) 
				for i=0, M-1 do model += coef[i]*templates.(i_include[i])[i_consider]

				
	
				if n_elements(variability_model) gt 0 and n_elements(systematics_model) gt 0 then begin
					i_systematics = where(fit[i_include].is_variability eq 0, M_systematics)
					i_variability = where(fit[i_include].is_variability, M_variability)
					variability_model[i_tonight] =0
					systematics_model[i_tonight] =0
					for i=0, M_variability-1 do variability_model[i_tonight] += coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
					for i=0, M_systematics-1 do systematics_model[i_tonight] += coef[i_systematics[i]]*templates.(i_include[i_systematics[i]])[i_tonight]

					if n_elements(uncertainty_variability_model) gt 0 and n_elements(uncertainty_overall_model) gt 0 then begin
						n_draws = 25
						ensemble_overall = fltarr(n_elements(i_tonight), n_draws)
						ensemble_variability = fltarr(n_elements(i_tonight), n_draws)
						for q=0, n_draws-1 do begin
							temporary_coef = draw_mvg(coef, covariances, 1)
							for i=0, M_variability-1 do ensemble_variability[*,q] += temporary_coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
							ensemble_variability[*,q] -= variability_model[i_tonight]
							for i=0, M_variability-1 do ensemble_overall[*,q] += temporary_coef[i_variability[i]]*templates.(i_include[i_variability[i]])[i_tonight]
							for i=0, M_systematics-1 do ensemble_overall[*,q]  += temporary_coef[i_systematics[i]]*templates.(i_include[i_systematics[i]])[i_tonight]
							ensemble_overall[*,q] -= (variability_model[i_tonight] + systematics_model[i_tonight])
						endfor
						uncertainty_variability_model[i_tonight] = sqrt(total(ensemble_variability^2, 2)/n_draws)
						uncertainty_overall_model[i_tonight] = sqrt(total(ensemble_overall^2,2)/n_draws)
					endif
						


				endif
	
				; evalute whether rescaling was okay	
				model_with_box = model
				model_with_box += coef[M_withbox-1]*A[*, M_withbox-1]*lc[i_consider].fluxerr*rescaling
				residuals = lc[i_consider].flux - model_with_box
				deviates_from_prior = (fit[i_include].coef - priors[i_include].coef)/priors[i_include].uncertainty
				chi_sq = total((residuals/lc.fluxerr)^2);+ total(deviates_from_prior^2)
	

				rescaling = sqrt((chi_sq + seasonwide_rescaling^2*n_effective_for_rescaling)/(n + n_effective_for_rescaling)) > 1
				count +=1; sqrt(chi_sq/n) > 1
			;	print, string(format='(F5.2)', previous_rescaling),  ' --> ',  string(format='(F5.2)',rescaling)
				converged = abs((rescaling - previous_rescaling)/rescaling) lt 0.01 or count gt 5
	
				fit[n_elements(fit)-1].coef = rescaling
				fit[n_elements(fit)-1].uncertainty = sqrt(chi_sq/n^2/2.0)
;					fit[where(fit.solved)].uncertainty*=fit[n_elements(fit)-1].coef	; make sure this is legit!
;					box.depth_uncertainty[k]*=fit[n_elements(fit)-1].coef	; make sure this is legit!
				box.rescaling[k] = rescaling
			endwhile
		;	print,''; '   ...', string(format='(F5.2)',rescaling),'!'
		endif
		; make some plots!	
		if keyword_set(display) and keyword_set(interactive)  and (box.depth[k]/box.depth_uncertainty[k] gt 1 ) and n_elements(i_consider) gt 1 and keyword_set(not_fake) then begin
			xplot
			erase
			smultiplot, /init, [2,2], colw=[1, .2], xgap=0.01, ygap=0.02

		
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
			i_calculated = where(box.depth_uncertainty ne 0, complement=i_notyet, n_calculated)
			ploterror, box.duration*24, box.depth, box.depth_uncertainty , /nodata, xs=3, psym=8, charsize=1, yno=0, xmargin=[!x.margin[0],100], xtitle='"Box" Duration', ytitle='"Box" Depth', yr=reverse(range(box.depth, box.depth_uncertainty > 0))
			if n_calculated ne n_elements(box.duration) then oploterror, box.duration[i_notyet]*24, box.depth[i_notyet], box.depth_uncertainty[i_notyet] 	, color=150, errcolor=150, psym=8
			if n_calculated ge 1 then oploterror, box.duration[i_calculated]*24, box.depth[i_calculated], box.depth_uncertainty[i_calculated], psym=8
			hline, 0, linestyle=2
			
		
			smultiplot
			loadct, 39, /silent
			if n gt 1 then begin
				t = lc[i_consider].hjd -  box.hjd
				yrange = [max( lc[i_consider].flux+2*lc[i_consider].fluxerr), min(  lc[i_consider].flux - 2*lc[i_consider].fluxerr)]
				ploterror, 24*t, lc[i_consider].flux, lc[i_consider].fluxerr, psym=8, title='NIGHT'+strcompress(/remo, tonight), xs=3, yrange=yrange, xtitle='Time from Mid-"Box" (hours)', ytitle='Flux (mag.)', charsize=1.5, charthick=2
				oplot, 24*t, model, color=250, thick=2, linestyle=2
				fine_t= findgen(301)/300*(max(t) - min(t)) + min(t)
				oplot, 24*fine_t, interpol(model, t, fine_t) + (abs(fine_t)  lt box.duration[k]/2)*box.depth[k],  color=250, thick=2
			endif else plot, [0]
			smultiplot, /def
			if question('curious?', interactive=interactive) then stop
		endif
	
		; demo plot
		if keyword_set(demo_plot) and (box.depth[k]/box.depth_uncertainty[k] gt -1000 or keyword_set(no_box)) and n_elements(i_consider) gt 1 then begin
			print, k
			keepgoing = 1
			while(keepgoing eq 1) do begin
				if keyword_set(do_eps) then begin
					set_plot, 'ps'
					if keyword_set(no_box) then prefix = 'no_box' else prefix = ''
					device, filename=prefix + 'marginalize_demo.eps', /encap, xsize=10, ysize=5, /inches, /colo
				endif
				t = lc[i_consider].hjd - box.hjd
				if not keyword_set(no_box) then !y.range = [max( lc[i_consider].flux+2*lc[i_consider].fluxerr), min(lc[i_consider].flux - 2*lc[i_consider].fluxerr)]
				ploterror, 24*t, lc[i_consider].flux, lc[i_consider].fluxerr, psym=8, xs=3, xtitle='Time from Mid-Transit (hours)', ytitle='Flux (mag.)',  charsize=1.2, charthick=3, xthick=3, ythick=3, title=stri
				n_demo = 10 + keyword_set(do_eps)*10
				for i_demo=0, n_demo-1 do begin
					demo_model = fltarr(n) 
					demo_coef = draw_mvg(coef, covariances*(fit[n_elements(fit)-1].coef)^2, 1)
					for i_democoef=0, M-1 do demo_model += demo_coef[i_democoef]*templates.(i_include[i_democoef])[i_consider]
					demo_model_with_box = demo_model
					demo_model_with_box += demo_coef[M_withbox-1]*A[*, M_withbox-1]*lc[i_consider].fluxerr
			
					loadct, file='~/zkb_colors.tbl', 54, /sil
					oplot, 24*t, demo_model, color=150, thick=1, linestyle=0
					fine_t= findgen(301)/300*(max(t) - min(t)) + min(t)
					loadct, file='~/zkb_colors.tbl', 42, /silent
				
					if not keyword_set(no_box) then  oplot, 24*fine_t, interpol(demo_model, t, fine_t) + (abs(fine_t)  lt box.duration[k]/2)*demo_coef[M_withbox-1],  color=120, thick=1
					if not keyword_set(no_box) and i_demo eq 0 then xyouts, 0+box.duration[k]*24/2, interpol(demo_model, t, 0) + box.depth[k], align=0.0, charthick=3, charsize=1.5, color=120, '='+strcompress(/remo, string(format='(F4.1)', box.depth[k]/box.depth_uncertainty[k]))+goodtex('\sigma')
					loadct, 0, /silent
				endfor
				theta = findgen(21)/20*2*!pi
				usersym, cos(theta), sin(theta), thick=5
				oploterror, 24*t, lc[i_consider].flux, lc[i_consider].fluxerr, psym=8, thick=5, errthick=5
				keepgoing = 0
				if keyword_set(do_eps) then begin
					device, /close
					set_plot, 'x'
					epstopdf, prefix + 'marginalize_demo.eps'
					do_eps = 0
					return, k
				endif
				if keyword_set(do_eps) then begin
					keepgoing = 1
					do_eps = 1
				endif
				if question('interested in demo?', /int) then begin
					keepgoing = 1
					do_eps = 1
				endif
			endwhile
		endif
	endfor
	return, box
END