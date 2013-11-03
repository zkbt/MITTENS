PRO plot_events, candidate, n_lc=n_lc, lc=lc, folder=folder, eps=eps, diagnosis=diagnosis, comparisons=comparisons, pdf=pdf
  common this_star
  if not keyword_set(candidate) then begin
    folder = 'blind/best/'
    restore, star_dir + folder + 'candidate.idl'
  endif
  
  if not keyword_set(n_lc) then n_lc=1        
  if not keyword_set(folder) then folder=''
  if not keyword_set(lc) then begin
      restore, star_dir + 'medianed_lc.idl'
      lc = medianed_lc
  endif
  i_it = where_intransit(lc, candidate, i_oot=i_oot, n_it)
  events = round((lc[i_it].hjd - candidate.hjd0)/candidate.period)
  uniq_events = events[uniq(events, sort(events))]
;  for i=0, n_elements(uniq_nights)-1 do begin
;    transit = {transit}
;    copy_struct, candidate, transit
;    this_transit = i_it[where(nights eq uniq_nights[i])]
;    transit.i_start = min(this_transit)
;    transit.i_stop = max(this_transit)
;    transit.hjd0 = (lc[transit.i_start].hjd + lc[transit.i_stop].hjd)/2.0
;    transit_number = round((transit.hjd0 - candidate.hjd0)/candidate.period)
;  if not keyword_set(eps) then  xplot, 20+i
; cleanplot, /silent
;  if not keyword_set(eps) then  xplot, 20+i
;  if not keyword_set(n_lc) then n_lc = 1
;    plot_lightcurves, n_lc, /time, transit=transit, wtitle=star_dir + ' | event #'+strcompress(/remov, transit_number)+' | HJD = ' + mjd2hopkinsdate(transit.hjd0), eps=eps,number=transit_number
;  endfor

  if not keyword_set(n_lc) then n_lc = 1
  xplot, 20
  i = 0
  !mouse.button=1
    while(!mouse.button lt 2 ) do begin
        transit = {transit}
    copy_struct, candidate, transit
    this_transit = i_it[where(events eq uniq_events[i])]
    transit.i_start = min(this_transit)
    transit.i_stop = max(this_transit)
    transit.hjd0 = candidate.hjd0 + round(mean(lc[this_transit].hjd - candidate.hjd0)/candidate.period)*candidate.period;(lc[transit.i_start].hjd + lc[transit.i_stop].hjd)/2.0
    transit_number = round((transit.hjd0 - candidate.hjd0)/candidate.period)
    !x.margin = [20,15]

      plot_lightcurves, n_lc, /time, transit=transit, wtitle=star_dir + ' | event #'+strcompress(/remov, transit_number)+' | HJD = ' + mjd2hopkinsdate(transit.hjd0), eps=eps,number=transit_number, diagnosis=diagnosis, comparisons=comparisons, pdf=pdf
      if keyword_set(eps) then begin
;        if question('eps?') then plot_lightcurves, n_lc, /time, transit=transit, wtitle=star_dir + ' | event #'+strcompress(/remov, transit_number)+' | HJD = ' + mjd2hopkinsdate(transit.hjd0), eps=eps,number=transit_number, diagnosis=diagnosis, comparisons=comparisons
      i += 1 
        if i eq n_elements(uniq_events) then return
      endif else begin
      
        plots, [0, 0.025, 0] + 0.95, [0.3, .5, 0.7], thick=5, /normal, color=125
        plots, -[0, 0.025, 0] + 0.05, [0.3, .5, 0.7], thick=5, /normal, color=125
        cursor, x, y, /down, /normal
        if x gt 0.5 then i = (i+1) < (n_elements(uniq_events)-1)
        if x lt 0.5 then i = (i-1) > 0
      endelse
    endwhile
    clear;    wdelete, !d.window
END