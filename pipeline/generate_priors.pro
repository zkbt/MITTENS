FUNCTION generate_priors, fit, thinair=thinair, bootstrap=bootstrap, assume_star_is_constant=assume_star_is_constant, assume_systematics_are_known=assume_systematics_are_known, assume_sin_is_known=assume_sin_is_known
	common this_star
	priors = replicate({name:'', coef:0.0, uncertainty:0.0}, n_elements(fit))
	priors.name = fit.name

	if keyword_set(thinair) then begin
		priors.coef = 0
		priors.uncertainty = 10
		priors[where(fit.is_variability and strmatch(fit.name, "COS*") eq 0 and strmatch(fit.name, "SIN*") eq 0)].uncertainty = 0.000001;0.01
		ye = long(stregex(/ext, stregex(/ext, star_dir(), 'ye[0-9]+'), '[0-9]+'))
		if ye eq 8 then begin
			cm_center =    0.00309362
			cm_width =  0.00195941
		endif
		if ye eq 9 then begin
			cm_center =    0.00379172
			cm_width = 0.00244113
		endif		
		if ye eq 10 then begin
			cm_center = 0.00724141
			cm_width =  0.00435500
		endif
		if ye eq 11 then begin
			cm_center =    0.00301826    
			cm_width =   0.00178824
		endif
		if ye eq 12 then begin
			cm_center =    0.00301826    
			cm_width =   0.00178824
		endif
		i_cm = where(strmatch(fit.name, "COMMON_MODE"), n_cm)
		if n_cm gt 0 then begin
			priors[i_cm].coef = cm_center
			priors[i_cm].uncertainty = cm_width
		endif
		i_merid = where(strmatch(fit.name, "*MERID*") or strmatch(fit.name, "*VERSION*"), n_merid)
		if n_merid gt 0 then begin
			priors[i_merid].coef =  0
			priors[i_merid].uncertainty = 0.005
		endif
		return, priors
	endif


	if keyword_set(assume_star_is_constant) then begin
		priors.coef = 0
		priors.uncertainty = 10
		priors[where(fit.is_variability and strmatch(fit.name, "COS*") eq 0 and strmatch(fit.name, "SIN*") eq 0)].uncertainty = 0.0001;0.01
		return, priors
	endif

	if keyword_set(bootstrap) then begin
		for i=0, n_elements(priors)-1 do begin
			priors[i].coef = median(bootstrap[i,*].coef)
			priors[i].uncertainty = mad(bootstrap[i,*].coef)
		endfor
		return, priors
	endif

	i_sys = where(fit.is_variability eq 0, n_sys)
	priors[i_sys].coef = fit[i_sys].coef
	priors[i_sys].uncertainty = fit[i_sys].uncertainty


	i_nights = where(strmatch(fit.name, 'NIGHT*'), n_nights)
	if n_nights gt 0 then begin
		hjd_nights = float(stregex(/extract, fit[i_nights].name, '[0-9]+'))
	; 	!p.multi = [0,1,2]
	; 	ploterror, hjd_nights, fit[i_nights].coef, fit[i_nights].uncertainty
	; 	plothist, fit[i_nights].coef, bin=0.005
	; 	oplot_gaussian, fit[i_nights].coef, bin=0.005
		if n_nights eq 1 then begin
			priors[i_nights].coef = fit[i_nights].coef
			priors[i_nights].uncertainty = 0.05
		endif else begin
			priors[i_nights].coef = median(fit[i_nights].coef)
			priors[i_nights].uncertainty = 1.48*mad(fit[i_nights].coef) > median(fit[i_nights].uncertainty)
			if 1.48*mad(fit[i_nights].coef) eq 0 then priors[i_nights].uncertainty=0.05
		endelse
	endif

	i_sin = where(strmatch(fit.name, 'COS*') or strmatch(fit.name, 'SIN*'), n_sin)
	if n_sin gt 0 then begin
		priors[i_sin].coef = fit[i_sin].coef
		priors[i_sin].uncertainty = fit[i_sin].uncertainty;/10.0
	endif

	if keyword_set(assume_systematics_are_known) then begin
		priors[where(fit.is_variability eq 0 and fit.solved)].uncertainty = 0.0001;0.01
		priors[where(fit.is_variability)].uncertainty = 10;0.01
	endif

	if keyword_set(assume_sin_is_known) and n_sin gt 0 then begin
		priors[i_sin].coef = fit[i_sin].coef
		priors[i_sin].uncertainty = 0.0001;fit[i_sin].uncertainty;/10.0
	endif	

	i_unconstrained = where(fit.uncertainty eq 0 and fit.solved, n_unconstrained)
	if n_unconstrained gt 0 then priors[i_unconstrained].uncertainty = 0.000001

	return, priors
END