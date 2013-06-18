FUNCTION generate_templates, target_lc=target_lc, common_mode_lc=common_mode_lc, no_nighttonight=no_nighttonight, no_xy=no_xy, n_harmonics=n_harmonics, period=period, no_sin=no_sin
;+
; NAME:
;    
;	generate_templates
; 
; PURPOSE:
; 
;	generate season-long templates to be used in a Bayesian light curve characterization scheme
; 
; CALLING SEQUENCE:
; 
;	  templates = generate_templates()
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
	if file_test(star_dir + 'sfit.idl') then 	restore, star_dir + 'sfit.idl' else no_sin=1

	; MAJOR KLUDGE TO MAKE A NICE PLOT FOR PROPOSALS
	if star_dir eq 'ls1186/ye08/te01/' then sfit.sfit_period = 52.5


	; interpolate the common mode (where we trust it) onto the light curve
	cm = load_common_mode()
	common_mode_lc = target_lc
	i_reliable = where(cm.n gt cm_minimum_n and cm.n_fields gt cm_minimum_n_fields, n_reliable, complement=i_unreliable)


	; increase uncertainty to stddev of the CM where we don't have a good estimate
	if i_unreliable[0] ne -1 then begin
		cm[i_unreliable].flux = 0.0
		cm[i_unreliable].fluxerr = stddev(cm.flux)
	endif

	; do the interpolation + keep track of the common mode in the ext_var variable
	common_mode_lc.flux = zinterpol(cm.flux, cm.mjd_obs, ext_var.mjd_obs)
	common_mode_lc.fluxerr = zinterpol(cm.fluxerr, cm.mjd_obs, ext_var.mjd_obs)
;	cleanplot
;	xplot
;	plot, common_mode_lc.flux
	
;	if stddev(ext_var.common_mode) eq 0 then begin
		ext_var.common_mode = common_mode_lc.flux
		save, ext_var, filename=star_dir + 'ext_var.idl'
;	endif
	
	; include certain external variables that must be included in the decorrlation
	ev_structure_tag_names = tag_names(ext_var) 
	i_ev = where(ev_structure_tag_names eq ev_tags[0])
	for i=1, n_elements(ev_tags)-1 do begin
		i_ev_temp = where(ev_structure_tag_names eq ev_tags[i])
		; throw out external variables that don't vary!
		if stddev(ext_var.(i_ev_temp)) gt 0 then begin
			i_ev = [i_ev, i_ev_temp] 
		endif
		
	endfor
	templates = create_struct('CONSTANT', ones(n_elements(ext_var)))
	for i=0, n_elements(i_ev)-1 do if total(finite(ext_var.(i_ev[i]))) gt 2 then templates = create_struct(templates, ev_structure_tag_names[i_ev[i]], float(ext_var.(i_ev[i])))


	; add a variable for each segment (this includes a meridian flip for each instrument flip)
	versions = ext_var[uniq(ext_var.iver, sort(ext_var.iver))].iver
	for i=0, n_elements(versions)-1 do begin
		i_ver = where(ext_var.iver eq versions[i], n_ver)
		if n_ver gt 0 then begin
			segments = ext_var[i_ver[uniq(ext_var[i_ver].iseg, sort(ext_var[i_ver].iseg))]].iseg
			if i gt 0 then templates = create_struct(templates, 'version'+string(form='(I02)', versions[i]), float(ext_var.iver eq versions[i]))
			if n_elements(segments) eq 2 then templates = create_struct(templates, 'merid_version'+string(form='(I02)', versions[i]), float(ext_var.iseg eq segments[1]))
			if n_elements(segments) eq 0 or n_elements(segments) gt 2 then begin
				print, 'TROUBLE MAKING TEMPLATES FOR SEGMENTS'
				stop
			endif
		endif
	endfor

	if ~keyword_set(no_nighttonight) then begin
		; add in another variable for each night, allowing for variability
		nights = round(target_lc.hjd-mearth_timezone())
		uniq_nights = nights[uniq(nights, sort(nights))]
		for i=0, n_elements(uniq_nights)-1 do templates = create_struct(templates, 'NIGHT'+strcompress(/remo, uniq_nights[i]), float(nights eq uniq_nights[i]))
	endif

	if ~keyword_set(no_sin) then begin
		;include two templates for sin + cos
		if sfit.sfit_period gt 0 and sfit.sfit_period lt 1000 then begin;and sfit.sfit_amp*2*!pi/sfit.sfit_period gt 0.002 then begin
			if ~keyword_set(n_harmonics) then n_harmonics = 1
			for i=1, n_harmonics do begin
				period = sfit.sfit_period/i
				period_string = str_replace(string(period, format='(F09.4)'), '\.','_')
				angular_frequency = 2*!pi/double(period)
				templates = create_struct(templates, 'SIN_'+period_string, sin(angular_frequency*target_lc.hjd))
				templates = create_struct(templates, 'COS_'+period_string, cos(angular_frequency*target_lc.hjd))
			endfor
		endif
	endif

	if ~keyword_set(no_xy) then begin
		; include x and y terms median(ext_var.left_xlc)
		pointing_tags = ['LEFT_XLC', 'RIGHT_XLC', 'LEFT_YLC', 'RIGHT_YLC']
		for i=0, n_elements(pointing_tags)-1 do begin
			i_xy = where(strmatch(ev_structure_tag_names, pointing_tags[i]), n_xy)
			if n_xy gt 0 then begin
				if total(finite(ext_var.(i_xy))) gt 2 and stddev(ext_var.(i_xy)) gt 0 then templates = create_struct(templates, pointing_tags[i_xy], ext_var.(i_xy) - median(ext_var.(i_xy)))
			endif
		endfor
	endif
	
	;templates = create_struct(templates, 'CONSTANT', fltarr(n_elements(target_lc.hjd))+1.0)
	return, templates
END


