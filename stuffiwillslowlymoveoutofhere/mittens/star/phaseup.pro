PRO phaseup, transit, n_lc=n_lc, n_peaks=n_peaks, eps=eps, folder=folder, candidate=candidate, fast=fast, lc=lc
;+
; NAME:
;	PHASEUP
; PURPOSE:
;	phase up any individual transit
; CALLING SEQUENCE:
;	phaseup, transit, n_lc=n_lc, n_peaks=n_peaks, eps=eps, folder=folder, candidate=candidate, fast=fast, lc=lc
; INPUTS:
;	transit = structure containing anchoring event
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
;	n_lc=n_lc, n_peaks=n_peaks, eps=eps, folder=folder, candidate=candidate, fast=fast, lc=lc
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
  response = strarr(1)
  if keyword_set(display) then cleanplot, /silent
      mprint, '------------------------------------------------------------'
      mprint, tab_string, 'phasing up the following transit into ', folder
      print_transit, transit
  
  @psym_circle
  if file_test(star_dir + 'medianed_lc.idl') eq 0 then return
  if not keyword_set(lc) then begin
    restore, star_dir + 'medianed_lc.idl'
    lc = temporary(medianed_lc)
    lc = lc[where(lc.okay)]
  endif
  if not keyword_set(n_peaks) then n_peaks = 1
    
  ; period range to consider (days)
  p_min = (5.0/4.2*lspm_info.radius/lspm_info.mass^(1.0/3.0)) > 0.5
  p_max = 20.0

  ; convert to frequency range (inverse days)
  v_min = 1.0d/p_max
  v_max = 1.0d/p_min
  v_bin = 5.0d/60.0/24.0/(max(lc.hjd) - min(lc.hjd))

  ; construct period search array
  n_periods = long((v_max - v_min)/v_bin) + 1
  periods = 1.0/(dindgen(n_periods)*v_bin + v_min)
  
  ; use physical information
  mass = lspm_info.mass
  radius = lspm_info.radius
  a_over_r = 4.2/radius*mass^(1.0/3.0)*periods^(2.0/3.0)
  durations = periods/a_over_r/4.0 ;fltarr(n_periods) + transit.duration;
  depth = transit.depth
  it_level = fltarr(n_periods)
  oot_level = fltarr(n_periods)
  deltachi = fltarr(n_periods)
  n_nights = fltarr(n_periods)
  nights = long(lc.hjd)
  
  n = intarr(n_periods)
  mprint, tab_string, doing_string, 'searching ', strcompress(/remo, n_periods), ' periods from ', string(format='(F4.2)', p_min), ' to ', strcompress(/remo, string(format='(F5.2)', p_max))
  pad = long((max(lc.hjd) - min(lc.hjd))/p_min)+1
  temp_candidate = {candidate}
  for i=0L, n_periods-1 do begin
  ; phase time to the appropriate period
    temp_candidate.period = periods[i]
    temp_candidate.duration = durations[i]
    temp_candidate.hjd0 = transit.hjd0
    i_intransit = where_intransit(lc, temp_candidate, n_it)
;    phased_time = (lc.hjd-transit.hjd0)/periods[i] + pad + 0.5
;    orbit_number = long(phased_time)
;    phased_time = phased_time - orbit_number - 0.5
;    h = histogram(phased_time, min=-durations[i]/2.0, max=durations[i]/2.0, bin=durations[i], reverse_indices=ri)
;    if h[0] eq 0 then continue 
;    n[i] = h[0]
;    i_intransit = ri[ri[0]:ri[1]-1]

    if n_it eq 0 then continue
    n[i] = n_it
    weightedsum = total(lc[i_intransit].flux/lc[i_intransit].fluxerr^2, /double)
    inversevarsum = total(1.0/lc[i_intransit].fluxerr^2, /double)
    inversevarsumall = total(1.0/lc.fluxerr^2, /double)
    it_level[i] = weightedsum/inversevarsum/(1.0d - inversevarsum/inversevarsumall)
    oot_level[i] = -weightedsum/inversevarsumall/(1.0d - inversevarsum/inversevarsumall)
    deltachi[i] = weightedsum*it_level[i]
    n_nights[i] = n_elements(uniq(nights[i_intransit]))

    ;deltachi *= (it_level gt 0)
    
;    if i mod 989 eq 0 then begin
;      !p.multi=[0,2,2]
;      !x.range = [-periods[i], periods[i]]/2
;      plot, [phased_time, phased_time + periods[i]],[lc.flux, lc.flux], psym=3, yrange=[max(lc.flux), min(lc.flux)], xstyle=1, /nodata
;      oplot, [-periods[i], -durations[i]/2, -durations[i]/2, durations[i]/2, durations[i]/2, periods[i]], [0,0,depth,depth,0,0], linestyle=1
;      oplot, [phased_time, phased_time + periods[i]],[lc.flux, lc.flux], psym=8
;      !x.range = [-5,5]*durations[i]
;      plot, [phased_time, phased_time + periods[i]],[lc.flux, lc.flux], psym=3, yrange=[max(lc.flux), min(lc.flux)], xstyle=1, /nodata
;      oplot, [-periods[i], -durations[i]/2, -durations[i]/2, durations[i]/2, durations[i]/2, periods[i]], [0,0,depth,depth,0,0], linestyle=1
;      oplot, [phased_time, phased_time + periods[i]],[lc.flux, lc.flux], psym=8
;      !x.range = 0
;      plot, 1.0/periods, deltachi, xtitle=goodtex('\Delta\chi^2')
;      peaks = peaks(deltachi)
;    endif
  endfor
  not_too_sharp = sqrt(abs(it_level))/(durations/2.0) lt 13.22*(lspm_info.mass/periods)^(1./3.)/lspm_info.radius
;  plot, 13.22*(lspm_info.mass/periods)^(1./3.)/lspm_info.radius
;  oplot, sqrt(abs(it_level))/(durations/2.0)
  
  deltachi *= (it_level gt 0 and not_too_sharp)
  i_infinite = where(finite(deltachi, /nan), n_infinite)
  if n_infinite gt 0 then deltachi[i_infinite] = 0.0
  peaks = select_peaks(deltachi, n_peaks)
;  peaks = peaks(smooth(deltachi,5))
;  peaks = reverse(peaks[sort(deltachi[peaks])])
  if not keyword_set(fast) and keyword_set(display) then begin
    !p.multi=[0,1,2]
    xplot, 10, title=star_dir + ' | fixed event phased folder'
    loadct, 39, /silent
    plot, 1.0/periods, deltachi, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('\chi^2 improvement of transit'), yrange=[0, max(deltachi)], xtick_get=xtick_get, ymargin=[4,4], charsize=1
    oplot, 1.0/periods, deltachi, linestyle=1
    axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F5.1)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
    plots, 1.0/periods[peaks[0:n_peaks-1]], deltachi[peaks[0:n_peaks-1]], psym=8, color=250
    i_max = peaks[where(deltachi[peaks] eq max(deltachi[peaks]))]
    plot, 1.0/periods, deltachi, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('\chi^2 improvement of transit'), yrange=[0, max(deltachi)], xtick_get=xtick_get, ymargin=[4,4], charsize=1, xrange=([-0.01, 0.01] + 1/periods[i_max[0]])
    
    oplot, 1.0/periods, deltachi, linestyle=1
    axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F5.1)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
    plots, 1.0/periods[peaks[0:n_peaks-1]], deltachi[peaks[0:n_peaks-1]], psym=8, color=250
    i_max = peaks[where(deltachi[peaks] eq max(deltachi[peaks]))]
  endif
  for j=0, n_peaks -1 do begin
    i = peaks[j]
    this = {candidate}
    this.period = periods[i]
    this.hjd0 = transit.hjd0
    this.duration = durations[i]
    i_intransit = where_intransit(lc, this, i_oot=i_oot, n_it)
    weightedsum = total(lc[i_intransit].flux/lc[i_intransit].fluxerr^2, /double)
    this.chi = weightedsum*it_level[i]
    this.n_int = n[i]
    this.depth = it_level[i]
;    phased_time = (lc.hjd-transit.hjd0)/periods[i] + pad + 0.5
;    orbit_number = long(phased_time)
;    phased_time = phased_time - orbit_number - 0.5
;    h = histogram(phased_time, min=-durations[i]/2.0, max=durations[i]/2.0, bin=durations[i], reverse_indices=ri)
;    if h[0] eq 0 then continue 
;    n[i] = h[0]
;    i_intransit = ri[ri[0]:ri[1]-1]

  
    if n_elements(all_candidates) eq 0 then all_candidates = this else all_candidates = [all_candidates, this]
   
     ; xplot, j+1, title=string(this.period)

;     if not keyword_set(fast) then begin
;       if keyword_set(eps) then begin
;         filename='best_phased_transit'
; ;        plot_lightcurves,n_lc, /phased, /time, candidate=this, /fixed, eps=folder+'best_fepf'
;       endif else begin
;      ;   plot_candidate, this
; ;         plot_lightcurves,n_lc, /phased, /time, candidate=this, /fixed, wtitle=star_dir + 'FEPF '+(folder)+' | ' + star_dir
;       end
;       !x.range = 0
;     endif

  endfor
  candidates = all_candidates
  candidate = all_candidates[0]
  candidate.f = calculate_f(lc, candidate)
  ;if question('would you like to view more details on this candidate?') then print_bls, this, folder=folder
  if keyword_set(display) then cleanplot, /silent
  save, filename=star_dir + folder + 'candidate.idl', candidate
  save, filename=star_dir + folder + 'initial_guess.idl', transit
  search_parameters = {n_periods:n_periods, min_duration:min(durations), max_duration:max(durations), min_period:min(periods), n_data:n_elements(lc), med_cadence:median(lc[1:*].hjd - lc[0:*].hjd)}
  save, filename=star_dir + folder + 'search_parameters.idl', search_parameters
  
  if not keyword_set(fast) then begin
    candidate.fap = merf(candidate, folder)
    save, filename=star_dir + folder + 'candidate.idl', candidate
    mprint, tab_string, 'the following candidate was saved to ', star_dir + folder
    print_candidate, candidate
  endif
END