PRO clean_lightcurve,  injection_test=injection_test, antitransit_test=antitransit_test, remake=remake, folder=folder, target_lc=target_lc, medianed_lc=medianed_lc
;+
; NAME:
;	CLEAN_LIGHTCURVE
; PURPOSE:
;	fit for and remove systematics and stellar variability from MEarth light curves (crucial input for transit search!)
; CALLING SEQUENCE:
;	clean_lightcurve,  injection_test=injection_test, antitransit_test=antitransit_test, remake=remake, folder=folder, target_lc=target_lc, medianed_lc=medianed_lc
; INPUTS:
;	restore, star_dir + folder +  'target_lc.idl'
;	restore, star_dir+ 'ext_var.idl'
;	restore, star_dir + 'sfit.idl'
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	/injection_test
;	/antitransit_test
; 	/remake
;	folder=folder
;	target_lc=target_lc
;	medianed_lc=medianed_lc
; OUTPUTS:
;       save, superfit, filename=star_dir + folder + 'superfit.idl'
;       save, decorrelated_lc, filename=star_dir  + folder + 'decorrelated_lc.idl'    
;       save, medianed_lc, filename=star_dir + folder + 'medianed_lc.idl'
;       save, ext_var, filename=star_dir+'ext_var.idl'
; RESTRICTIONS:
; EXAMPLE:
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-

	; setup environment
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	; file management

    if keyword_set(antitransit_test) then begin    
      if not keyword_set(folder) then folder = 'antitransit_test/'
      file_mkdir, star_dir + folder
    endif else begin
      if keyword_set(injection_test) then folder = 'injection_test/'
      folder = ''
    endelse

	if not keyword_set(target_lc) then restore, star_dir + folder +  'target_lc.idl'
	restore, star_dir+ 'ext_var.idl'
	restore, star_dir + 'sfit.idl'

  if is_uptodate(star_dir + folder + 'medianed_lc.idl', star_dir + folder + 'target_lc.idl') and not keyword_set(antitransit_test) and not keyword_set(injection_test)  and not keyword_set(remake) then begin
    mprint, skipping_string, 'light curve cleaning is up to date!'
    return
  endif
  
	; only bother with light curves that have substantial data
	if n_elements(target_lc) gt 5 or keyword_set(antitransit_test) or keyword_set(injection_test) then begin
   if not keyword_set(injection_test) then mprint,  doing_string, 'cleaning light curve for ', star_dir + folder

		; interpolate the common mode (where we trust it) onto the light curve
		cm = load_common_mode()
		common_mode_lc = target_lc
		i_reliable = where(cm.n gt cm_minimum_n and cm.n_fields gt cm_minimum_n_fields, n_reliable, complement=i_unreliable)

		; increase uncertainty to stddev of the CM where we don't have a good estimate
		cm[i_unreliable].flux = 0.0
		cm[i_unreliable].fluxerr = stddev(cm.flux)

		; do the interpolation + keep track of the common mode in the ext_var variable
		common_mode_lc.flux = interpol(cm.flux, cm.mjd_obs, ext_var.mjd_obs)
		common_mode_lc.fluxerr = interpol(cm.fluxerr, cm.mjd_obs, ext_var.mjd_obs)
		ext_var.common_mode = common_mode_lc.flux
		
		; allow certain external variables to enter into the pool of templates for possible decorrelation	
		ev_structure_tag_names = tag_names(ext_var) 
		i_ev = where(ev_structure_tag_names eq ev_tags[0])
		for i=1, n_elements(ev_tags)-1 do begin
			i_ev_temp = where(ev_structure_tag_names eq ev_tags[i])
			; throw out external variables that don't vary!
			if stddev(ext_var.(i_ev_temp)) gt 0 then begin
				i_ev = [i_ev, i_ev_temp] 
			endif
		endfor
		templates = create_struct(ev_structure_tag_names[i_ev[0]], ext_var.(i_ev[0]))
		for i=1, n_elements(i_ev)-1 do templates = create_struct(templates, ev_structure_tag_names[i_ev[i]], float(ext_var.(i_ev[i])))

    ; add in another variable for each night, allowing for variability
		nights = round(target_lc.hjd-0.292)
		uniq_nights = nights[uniq(nights, sort(nights))]
		for i=0, n_elements(uniq_nights)-1 do templates = create_struct(templates, 'NIGHT'+strcompress(/remo, uniq_nights[i]), float(nights eq uniq_nights[i]))

		;include two templates for sin + cos
		if sfit.sfit_period gt 0 and sfit.sfit_period lt 1000 and sfit.sfit_amp*2*!pi/sfit.sfit_period gt 0.002 then begin
			n_harmonics = 1
			for i=1, n_harmonics do begin
				period = sfit.sfit_period/i
				period_string = strcompress(string(period*100, format='(I05)'), /remove_all)
				angular_frequency = 2*!pi/double(period)
				templates = create_struct(templates, 'SIN_'+period_string, sin(angular_frequency*target_lc.hjd))
				templates = create_struct(templates, 'COS_'+period_string, cos(angular_frequency*target_lc.hjd))
			endfor
		endif
		templates = create_struct(templates, 'CONSTANT', fltarr(n_elements(target_lc.hjd))+1.0)

    tags = tag_names(templates)
 ;   mprint,  tab_string, 'allowing the following templates in the cleaning fit:'
  ;  mprint,  tab_string, tags[where(strmatch(tags, 'NIGHT*') eq 0)]
    
;		; use other field stars with LOW noise for decorrelation templates
;		comparisons_scatter = (total((comparisons_lc.flux)^2, 1, /nan)/(n_elements(target_lc.flux)-1))^0.5	;1.48*median(abs(comparisons_lc.flux), dimen=1)
;		i_good_comps = where(comparisons_scatter lt comparison_star_noise_excess_factor*stddev(target_lc.flux) and comparisons_scatter gt 0, n_good_comps)
;		if n_good_comps gt 0 then begin
;			star_labels = 'STAR'+strcompress(/remove_all, comparisons_pointers[i_good_comps])
;			for i=0, n_elements(star_labels)-1 do templates = create_struct(templates, star_labels[i], comparisons_lc[*,i_good_comps[i]].flux)
;		endif
	  lc = target_lc
if keyword_set(antitransit_test) then begin
      mprint,  tab_string, "running an inverted light curve test - don't believe anything!"
      lc.flux *= -1
    endif
		
		
		;ignore biggest outliers
    lc.okay = target_lc.okay and abs(target_lc.flux) lt 10*stddev(target_lc.flux)

    ; run initial decorrelation fit
    temp = superfit(lc, templates, star_dir)
   ; plot_superfit, temp
    
    ;update CM uncertainty + outlier rejection
;    lc.fluxerr = sqrt(target_lc.fluxerr^2 + common_mode_lc.fluxerr^2)
    dev = temp.cleaned/lc.fluxerr
    rms = 1.48*mad(dev)
    lc.okay = target_lc.okay and abs(dev) lt 4*rms
    temp = superfit(lc, templates, star_dir)
	i_cm_fit = where(temp.fit.name eq 'COMMON_MODE', n_cm_fit)
	if n_cm_fit gt 0 then cm_coef = temp.fit[i_cm_fit].coef else cm_coef = 1.0
  lc.fluxerr = sqrt(target_lc.fluxerr^2 + cm_coef^2*common_mode_lc.fluxerr^2)

  ;  plot_superfit, temp
    
    ; update for possible presence of transits within nights
    if keyword_set(display) then loadct, 0, /silent
    i_ok = where(lc.okay, n_ok)
    rescaling1 = sqrt(total(temp.cleaned[i_ok]^2/lc[i_ok].fluxerr^2)/n_ok) > 1
    for i=0, n_elements(uniq_nights)-1 do begin
      i_goodthisnight = where(nights eq uniq_nights[i] and lc.okay, n_goodthisnight)
      if n_goodthisnight gt 0 then begin
        clean_lc = lc[i_goodthisnight]
        clean_lc.flux = temp.cleaned[i_goodthisnight]
        clean_lc.fluxerr *= rescaling1
        transit = find_the_transit(clean_lc)
        if n_tags(transit) gt 1 then begin
          ;if n_elements(best_nightly_transits) eq 0 then best_nightly_transits = transit else best_nightly_transits = [best_nightly_transits, transit]
          if transit.p lt 1.0/n_elements(target_lc) then lc[i_goodthisnight[transit.i_start:transit.i_stop]].okay = 0
        endif
      endif  
    endfor
    superfit = superfit(lc, templates, star_dir)
  ; plot_superfit, superfit, /eps
  ;  if not keyword_set(antitransit_test) and 
    if not keyword_set(antitransit_test) and keyword_set(display) then plot_superfit, superfit
    
    i_ok = where(lc.okay)
    lc.fluxerr *= rescaling1
    lc.okay = 1
    decorrelated_lc = lc
    decorrelated_lc.flux -= superfit.decorrelation
    medianed_lc = lc
    medianed_lc.flux = superfit.cleaned
  ;  medianed_lc.fluxerr = sqrt(lc.fluxerr^2 + superfit.variability_uncertainty^2)
    
    ; too rapid of variation
    forward_deriv = (medianed_lc[1:*].flux - medianed_lc[0:*].flux)/(medianed_lc[1:*].hjd - medianed_lc[0:*].hjd)
    too_sharp = abs(forward_deriv) gt 13.2*lspm_info.mass^(1./3.)/lspm_info.radius ;crossing time for dark star in a 1 day orbit
    i_toosharp = where(too_sharp, n_too_sharp)
    if n_too_sharp gt 0 then medianed_lc[i_toosharp].okay = 0
   ; medianed_lc.okay = abs(medianed_lc.flux/medianed_lc.fluxerr) lt 10
    rescaling2 = sqrt(total(superfit.cleaned[i_ok]^2/medianed_lc[i_ok].fluxerr^2)/n_ok); > 1
    medianed_lc.fluxerr *= rescaling2
    i_ok = where(medianed_lc.okay)
  
  if not keyword_set(injection_test) then   begin
    mprint,  tab_string, 'uncertainties rescaled by ', strcompress(/remo, string(format='(F5.2)', rescaling1*rescaling2))
    mprint,  tab_string, tab_string, 'initial RMS = ', strcompress(/remo, string(format='(F5.3)', stddev(target_lc[i_ok].flux)))
    mprint,  tab_string, tab_string, '  final RMS = ', strcompress(/remo, string(format='(F5.3)', stddev(medianed_lc[i_ok].flux)))
    endif


    ; save the files
    if not keyword_set(antitransit_test) and not keyword_set(injection_test)  then begin
      save, superfit, filename=star_dir + folder + 'superfit.idl'
      save, decorrelated_lc, filename=star_dir  + folder + 'decorrelated_lc.idl'    
      save, medianed_lc, filename=star_dir + folder + 'medianed_lc.idl'
      save, ext_var, filename=star_dir+'ext_var.idl'

      mprint,  tab_string, 'saved files to ', star_dir + folder
    endif
   if not keyword_set(injection_test) then  mprint,  done_string
	endif
END