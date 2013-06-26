 PRO rough_clean, use_sin=use_sin, remake=remake, cleaned_lc=cleaned_lc, variability_lc=variability_lc
	common mearth_tools
	common this_star

	if keyword_set(use_sin) then begin
		filename = 'roughly_cleaned_toward_sin_lc.idl'
		summary_filename =  'roughly_toward_sin_summary.idl'
	endif else begin
		filename = 'roughly_cleaned_toward_flat_lc.idl'
		summary_filename =  'roughly_toward_flat_summary.idl'
	endelse

	; avoid duplication of effort
	if is_uptodate(star_dir + filename, star_dir  + 'target_lc.idl') and ~keyword_set(remake)  then begin
    		mprint, skipping_string, 'roughly cleaning LC is up-to-date'
		return
	endif
	if keyword_set(use_sin) then str = '(to sinusoid)' else str='(to flat)'
	mprint, doing_string, 'doing a rough clean of the light curve to assess noise levels '+str
	if file_test( star_dir  + 'target_lc.idl') eq 0 then begin
		mprint, skipping_string, ' no enough data points in the weeded light curve to bother continuing!'
		return
	end
	; load light curve + set up templates and fits
	restore, star_dir +  'target_lc.idl'

	; set up the systematics + variability templates
	templates = generate_templates(target_lc=target_lc, common_mode_lc=common_mode_lc, /no_nighttonight, /no_xy, period=period, no_sin=~keyword_set(use_sin))

	; clean up the templates (zero average and rescale, e.g.)
	initialized_fit = setup_bayesfit(target_lc, templates, use_sin=use_sin, /use_constant)

	; start with priors drawn from thin air
	thinair_priors = generate_priors(initialized_fit, /thinair)

	; fit all the data with base systematics + sin + cos + a constant
	season_fit = bayesfit(target_lc, templates, initialized_fit, thinair_priors, residuals=residuals)
	i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
; 	mprint, 'first pass at parameters'
; 	print_struct, season_fit[i_fit]

	; inflate the errors to include common mode uncertainty
	i_cm =  where(strmatch(season_fit.name, 'COMMON_MODE') )
	cm_scale = season_fit[i_cm].coef/season_fit[i_cm].rescaling
	inflated_lc = target_lc
	other_tel = ~strmatch(star_dir, '*te0*')
	if ~other_tel then inflated_lc.fluxerr = sqrt(target_lc.fluxerr^2 + (cm_scale*common_mode_lc.fluxerr)^2)

	season_fit = bayesfit(inflated_lc, templates, initialized_fit, thinair_priors, residuals=residuals)
	i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
; 	print, 'parameters after inflating by CM error'
; 	print_struct, season_fit[i_fit]

	; clip outliers (in both directions), just for setting priors
	clipped_lc = inflated_lc
	i_outliers = where(abs(residuals/1.48/mad(residuals)) gt 3, n_outliers, complement=i_ok)
	if n_outliers gt 0 then clipped_lc[i_outliers].okay = 0

	rough_fit = bayesfit(clipped_lc, templates, initialized_fit, thinair_priors, residuals=residuals, systematics_model=systematics_model, variability_model=variability_model)
	i_fit = where(season_fit.solved and strmatch(season_fit.name, 'NIGHT*') eq 0, n_fit)
; 	print, 'parameters after 1) inflating by the CM, and 2) clipping egregious outliers'
; 	print_struct, rough_fit

	if keyword_set(display) then begin
		loadct, 0, /silent
		xplot, title=star_dir() + ' rough cleaning'
		loadct, 39,/sil
		!p.multi=[0,2,3, 0,1]
		ploterror, inflated_lc.hjd,  inflated_lc.flux, inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
		plots,  inflated_lc.hjd, systematics_model + variability_model, color=250
		
		ploterror, inflated_lc.hjd,  inflated_lc.flux - systematics_model , inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
		plots,  inflated_lc.hjd, variability_model, color=250, psym=3
		
		ploterror, inflated_lc.hjd,  inflated_lc.flux - systematics_model - variability_model, inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
		hline, 0, color=250
	
		if keyword_set(use_sin) and keyword_set(period) then begin
			x = inflated_lc.hjd mod period
			ploterror, x, inflated_lc.flux, inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
			plots,  x, systematics_model + variability_model, color=250
			
			ploterror, x,  inflated_lc.flux - systematics_model , inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
			plots,  x, variability_model, color=250, psym=3
			
			ploterror, x,  inflated_lc.flux - systematics_model - variability_model, inflated_lc.fluxerr, psym=8, yr=reverse(range(inflated_lc.flux, inflated_lc.fluxerr))
			hline, 0, color=250
		endif
	endif

	roughly_cleaned_lc = inflated_lc
	roughly_cleaned_lc.flux = inflated_lc.flux - systematics_model - variability_model
	n_sigma = roughly_cleaned_lc.flux/roughly_cleaned_lc.fluxerr
	
	if keyword_set(forplotting) then begin
		cleaned_lc = roughly_cleaned_lc
		variability_lc = roughly_cleaned_lc
		variability_lc.flux += variability_model
	endif

	save, roughly_cleaned_lc, rough_fit, filename=star_dir+filename
	i_resc = where(rough_fit.name eq 'UNCERTAINTY_RESCALING', n_resc)
	if n_resc gt 0 then begin
		rescaling = rough_fit[i_resc].coef
		rescaling_unc = rough_fit[i_resc].uncertainty
	endif

	rough_summary = {rescaling:rescaling, uncertainty_in_rescaling:rescaling_unc, chisq:total((roughly_cleaned_lc.flux/roughly_cleaned_lc.fluxerr)^2), dof:n_elements(roughly_cleaned_lc) - n_fit, n_points:n_elements(roughly_cleaned_lc), n_4sig_outliers_up:total(n_sigma lt -4), n_4sig_outliers_down:total( n_sigma gt 4)}
;	print_struct, rough_summary
	save, rough_summary, filename=star_dir + summary_filename
END

