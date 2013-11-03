FUNCTION find_the_transit, input_lc,  all=all, threshold=threshold, deltachi_start=deltachi_start
  common this_star
  lc = input_lc[where(input_lc.okay)]
  n = n_elements(lc)
  if not keyword_set(threshold) then threshold = 1.0
  min_a_over_rs = 1.0
  minperiod = (min_a_over_rs*lspm_info.radius/4.2/lspm_info.mass)^1.5
  minduration = minperiod/a_over_rs(lspm_info.mass, lspm_info.radius, minperiod)/4.0
  
  tp = 300.0
  maxperiod = (lspm_info.teff/tp)^3*(1/8.4)^1.5*lspm_info.radius^1.5/lspm_info.mass^0.5
  maxduration = maxperiod/a_over_rs(lspm_info.mass, lspm_info.radius, maxperiod)/4.0
  
  if n gt 1 then begin
    if not keyword_set(max_points) then max_points = 50 < (n-1)
    padding = lc[0]
    padding.hjd = lc[n-1].hjd + 1.0/24.0
    padding.flux = 0.0
    padding.fluxerr = 100000.0
    padding.okay = 1.0
    padded_lc = [lc, replicate(padding, max_points)]
    oot_level = fltarr(n, max_points)
    it_level = fltarr(n, max_points)
    deltachi = fltarr(n, max_points)
    duration = fltarr(n, max_points)
    points = indgen(max_points)+1
    for i=0, max_points-1 do begin
      i_intransit = indgen(n)#ones(points[i]) + ones(n)#indgen(points[i])
      if i gt 0 then begin
        weightedsum = total(padded_lc[i_intransit].flux/padded_lc[i_intransit].fluxerr^2, 2, /double)
        inversevarsum = total(1.0/padded_lc[i_intransit].fluxerr^2, 2, /double)
      endif else begin
        weightedsum = (lc[i_intransit].flux/lc[i_intransit].fluxerr^2)
        inversevarsum = (1.0/lc[i_intransit].fluxerr^2)
      endelse
      inversevarsumall = total(1.0/lc.fluxerr^2, /double)
      it_level[*,i] = weightedsum/inversevarsum/(1.0d - inversevarsum/inversevarsumall)
      oot_level[*,i] = -weightedsum/inversevarsumall/(1.0d - inversevarsum/inversevarsumall)
      deltachi[*,i] = weightedsum*it_level[*,i]
      duration[*,i] = lc[i_intransit[*,0]+points[i]].hjd - lc[i_intransit[*,0]].hjd
;        erase
;        multiplot, [1,n], /init
;        for j=0, n-1 do begin
  ;        multiplot
  ;        ploterror, lc.hjd, lc.flux, lc.fluxerr, psym=8, yrange=[max(lc.flux+lc.fluxerr), min(lc.flux-lc.fluxerr)]
  ;        model = fltarr(n_elements(lc)) + oot_level[j]
  ;        model[i_intransit[j,*]] += it_level[j]
  ;        xyouts, lc[j].hjd, 0, string(format='(F5.3)', chisqr_pdf(deltachi[j,i], 1))
  ;        oplot, lc.hjd, model, color=150, psym=10
  ;      endfor  
  ;      multiplot, /def
    endfor
;    IF KEYWORD_SET(all) then begin
;      transit_ccdf = ccdf(max(deltachi*(it_level gt 0), dim=2))
;      antitransit_ccdf = ccdf(max(deltachi*(it_level lt 0), dim=2))
;      plot, antitransit_ccdf.x, antitransit_ccdf.y, xrange=[0.1,max(antitransit_ccdf.x)], /xlog, /ylog
;      oplot, transit_ccdf.x, transit_ccdf.y, color=150
;      stop
;    endif
   duration_constraint = duration gt minduration and duration lt maxduration and duration lt 0.75*(lc[n-1].hjd - lc[0].hjd)
   deltachi *= (it_level gt 0 and duration_constraint)
   
    if keyword_set(all) then begin
      deltachi_threshold = chisqr_cvf(threshold, 1)
      deltachi_start = max(deltachi*(it_level gt 0), dim=2)
      peak = select_peaks(deltachi_start, 20)
      i_pass = where(deltachi_start[peak] gt deltachi_threshold, n_pass)
      ;plot, deltachi_start
     ; hline, deltachi_threshold
      if n_pass gt 0 then begin
        peak = peak[i_pass]
       ; oplot, peak, deltachi_start[peak], psym=8
        for i=0, n_pass-1 do begin
          i_start = peak[i]
          i_duration = where(deltachi[peak[i],*] eq max(deltachi[peak[i],*]))
          i_duration = i_duration[0]
          i_stop = i_start + points[i_duration]-1
          temp = {depth:it_level[i_start, i_duration], deltachi:deltachi[i_start, i_duration], p:1-chisqr_pdf(deltachi[i_start, i_duration], 1),  i_start:i_start, i_stop:i_stop, hjd0:(lc[i_start].hjd + lc[i_stop].hjd)/2.0, duration:duration[i_start, i_duration]}
          if n_elements(result) eq 0 then result = temp else result = [result, temp]
        endfor
      endif else result = {p:1.0}
    endif else begin
      peak = where(deltachi eq max(deltachi), i_peak)
      peak = peak[0]
      ai_peak = array_indices(deltachi, peak)
      i_start = ai_peak[0]
      if n gt 2 then i_stop = i_start + points[ai_peak[1]] - 1 else i_stop = i_start
      result = {depth:it_level[peak], deltachi:deltachi[peak], p:1-chisqr_pdf(deltachi[peak], 1),  i_start:i_start, i_stop:i_stop, hjd0:(lc[i_start].hjd + lc[i_stop].hjd)/2.0, duration:duration[peak]}
    endelse
  endif else begin
      result = {p:1.0}
  endelse
  return, result
END