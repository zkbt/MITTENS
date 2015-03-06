FUNCTION calculate_f, lc, candidate
  i_it = where_intransit(lc, candidate, i_oot=i_oot, n_it)
  events = round((lc[i_it].hjd-candidate.hjd0)/candidate.period)
  uniq_events= events[uniq(events, sort(events))]
  n = n_elements(uniq_events)
  f_events = fltarr(n)
  for i=0, n-1 do begin
    i_intransit = i_it[where(events eq uniq_events[i])]
    weightedsum = total(lc[i_intransit].flux/lc[i_intransit].fluxerr^2, /double)
    f_events[i] = weightedsum*candidate.depth/candidate.chi
  endfor
  return, max(f_events)
END