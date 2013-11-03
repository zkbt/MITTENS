PRO estimate_sensitivity, remake=remake, cutoff, trigger=trigger, eps=eps, sensitivity_filename=sensitivity_filename
; NAME:
;	ESTIMATE_SENSITIVITY
; PURPOSE:
;	for one star, estimate sensitivity to transits
; CALLING SEQUENCE:
;	estimate_sensitivity, remake=remake, gauss=gauss
; INPUTS:
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:David Charbonneau
;	/remake = redo everything, whether or not its already been done
;	/gauss = use assumption uncorrelated Gaussian noise for significance estimation
; OUTPUTS:
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

  common this_star
  common mearth_tools
if keyword_set(trigger) then the_dir_with_the_fake = fake_trigger_dir else the_dir_with_the_fake=fake_dir
  	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/') + the_dir_with_the_fake


 filename = 'sensitivity_cutoff' + string(format='(F04.1)', cutoff) + '.idl'
	sensitivity_filename =  star_dir + filename

if is_uptodate(star_dir + filename, star_dir + 'injected_and_recovered.idl') and not keyword_set(remake) then return
if file_test( star_dir + 'injected_and_recovered.idl')  eq 0 then return
	restore, star_dir + 'injected_and_recovered.idl'

  mprint, doing_string, 'summarizing (over)-estimate of sensitivity for ', star_dir
  

  n_radii = n_elements(radii)
  p_min = 0.5
  p_max = 20.0
  bin=0.5
  n_periods = (p_max - p_min)/bin+1
  periods = findgen(n_periods)*bin + p_min + bin/2.0 
  sensitivity = fltarr(n_periods, n_radii)
  sensitivity_uncertainty = fltarr(n_periods, n_radii)
  wfunction = fltarr(n_periods, n_radii)
  wfunction_uncertainty = fltarr(n_periods, n_radii)

	trigger_cutoff = 3.0
	for i=0, n_elements(radii)-1 do begin
		i_radius = where(injected.radius eq radii[i], m)
		if m gt 0 then begin
			h_injected = histogram(injected[i_radius].period, bin=bin, min=p_min, max=p_max, locations=periods)
			if keyword_set(trigger) then begin
				i_detected = where(recovered[i_radius].n_sigma gt cutoff and recovered[i_radius].n_untriggered_sigma gt trigger_cutoff, n_detected)
			endif else begin
				i_detected = where(recovered[i_radius].n_sigma gt cutoff, n_detected)
			endelse
			i_wf = where(injected[i_radius].n_points gt 0, n_wf)
			if n_detected eq 0 then h_recovered = h_injected*0 else begin
				if n_detected eq 1 then begin
					h_recovered = h_injected*0
					h_recovered[value_locate(periods-bin/2.0, recovered[i_radius[i_detected]].period)]+=1
				endif else begin
					h_recovered = histogram(recovered[i_radius[i_detected]].period, bin=bin, min=p_min, max=p_max, locations=periods)
				endelse
			endelse
			if n_wf eq 0 then h_wf = h_injected*0 else begin
				if n_wf eq 1 then begin
					h_wf = h_injected*0
					h_wf[value_locate(periods-bin/2.0, recovered[i_radius[i_wf]].period)]+=1
				endif else begin
					h_wf =  histogram(recovered[i_radius[i_wf]].period, bin=bin, min=p_min, max=p_max, locations=periods)
				endelse
			endelse
			sensitivity[0:n_elements(h_recovered)-1,i] = float(h_recovered)/h_injected
			i_zero = where(h_injected eq 0, complement=i_ok, n_zero) 
			sensitivity_uncertainty[0:n_elements(h_recovered)-1,i] = sqrt(float(h_recovered))/h_injected
						wfunction[0:n_elements(h_wf)-1,i] = float(h_wf)/h_injected
			wfunction_uncertainty[0:n_elements(h_wf)-1,i] = sqrt(float(h_wf))/h_injected

			if n_zero gt 0 then sensitivity[i_zero,i] = interpol(sensitivity[i_ok, i], i_ok, i_zero)
			if n_zero gt 0 then wfunction[i_zero,i] = interpol(wfunction[i_ok, i], i_ok, i_zero)

	if keyword_set(interactive) then begin
cleanplot, /silent
				xplot, /top
			     !p.multi=[0,1,2]
			     loadct, 39, /silent
			     plot, periods, h_injected, title=string(radii[i]) + ' | ' + star_dir+ ' | cutoff ='+strcompress(cutoff) 
				oplot, periods, h_wf, linestyle=1, color=250
			     oplot, periods, h_recovered, color=250
			     ploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], yr=[0,1], /ys
				oplot, periods, wfunction[*,i], linestyle=1
			     if question(interactive=interactive, 'stop?') then stop
	endif

		endif
	endfor

	if keyword_set(eps) then begin
cleanplot, /silent

		file_mkdir, star_dir() +'plots/'
		epsfilename = star_dir() + 'plots/sensitivity.eps'
		set_plot, 'ps'
		device, filename=epsfilename, /encap, /color, xsize=6, ysize=2, /inches
		!p.charsize=0.6
		loadct, 39
  n_radii = n_elements(radii)
  radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90

		plot, [0], /nodata, xr=[0,20], yr=[0,1], ys=3
		for i=0, n_elements(radii)-1 do begin
			oplot, periods, sensitivity[*,i], color=radii_color[i]
		;	oploterror, periods, sensitivity[*, i], sensitivity_uncertainty[*, i], color=fix(i*254./n_elements(radii)), linestyle=0
		endfor
		oplot, periods, median(wfunction, dim=2), linestyle=1, color=0
		device, /close
		epstopdf, epsfilename
	endif
	save, periods, sensitivity, sensitivity_uncertainty, wfunction, wfunction_uncertainty, cutoff, filename =  star_dir + filename
	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
	
;   save, periods, sensitivity, sensitivity_uncertainty, deltachi, filename = star_dir + folder +filename
;  plot_sensitivity
  
END