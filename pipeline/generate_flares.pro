FUNCTION generate_flares, lc
;+
; NAME:
;	generate_flares
; PURPOSE:
;	generate season-long flares to be used in a Bayesian light curve characterization scheme
; CALLING SEQUENCE:
;	  flares = generate_flares()
; INPUTS:
; 
; KEYWORD PARAMETERS:
; 
; OUTPUTS:
;	
; RESTRICTIONS:
; 
; EXAMPLE:
; 
; MODIFICATION HISTORY:
; 	Written by ZKB.
;-

	; setup environment
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	min_decay_time = 0.001
	max_decay_time = 0.2
	n_decay_times = 10
	decay_time = 10^( findgen(n_decay_times)/(n_decay_times-1)*(alog10(max_decay_time) - alog10(min_decay_time)) + alog10(min_decay_time))
;(findgen(n_decay_times)+1)*max_decay_time/n_decay_times
	one_flare = {hjd:0.0d, decay_time:decay_time, height:fltarr(n_decay_times), height_uncertainty:fltarr(n_decay_times), n:fltarr(n_decay_times),  rescaling:fltarr(n_decay_times)}
	i_okay = where(lc.okay, n_okay)
	flares = replicate(one_flare, n_okay)
	flares.hjd =lc[i_okay].hjd
	
	return, flares
END