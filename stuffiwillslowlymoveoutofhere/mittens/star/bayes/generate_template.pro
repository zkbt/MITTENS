FUNCTION generate_template
;+
; NAME:
;    
;	generate_template
; 
; PURPOSE:
; 
;	generate season-long templates to be used in a Bayesian light curve characterization scheme
; 
; CALLING SEQUENCE:
; 
;	  templates = generate_template()
; 
; INPUTS:
;	
; 
; KEYWORD PARAMETERS:
; 
;	
; 
; OUTPUTS:
; 
;	
; 
; RESTRICTIONS:
; 
;	
; 
; EXAMPLE:
; 
;	
; 
; MODIFICATION HISTORY:
;
; 	Written by ZKB.
;
;-

	; setup environment
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	; load light curve + external variables + Jonathan's best guess for sin fit
	if not keyword_set(target_lc) then restore, star_dir +  'target_lc.idl'
	restore, star_dir+ 'ext_var.idl'
	restore, star_dir + 'sfit.idl'

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
	nights = round(target_lc.hjd-mearth_timezone())
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
	;templates = create_struct(templates, 'CONSTANT', fltarr(n_elements(target_lc.hjd))+1.0)
	return, templates
END