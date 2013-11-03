PRO jenkins_bootstrap, n_trials, reset=reset
  if not keyword_set(n_trials) then n_trials=100
  common this_star
  common mearth_tools
  
  if file_test(star_dir + 'medianed_lc.idl') eq 0 then begin
    mprint, skipping_string, 'not enough data to do the Jenkins bootstrap'
    return
  endif
  mprint, doing_string, 'running Jenkins boostrap on ', star_dir, ' with ', strcompress(/remo, n_trials), ' samples'
  restore, star_dir + 'medianed_lc.idl'
  i_ok = where(medianed_lc.okay, n)
  lc = medianed_lc[i_ok]
  lc.fluxerr = median(lc.fluxerr)
  while(!d.window ge 0) do wdelete
  f = file_search(star_dir + 'eit/*/')
  start = n_elements(f)

  if keyword_set(reset) then begin
    if n_elements(f) gt 1 then file_delete, f, /recursive, /verbose
    start=0
  endif
  for i=start, start+n_trials-1 do begin
   
    folder = 'eit/'+strcompress(/remo, i) + '/'
    file_mkdir, star_dir + folder
    
    lc.flux = randomn(seed, n)*lc.fluxerr
    transits = find_the_transit(lc, threshold=0.5, /all)
    transits = transits[0:4 < (n_elements(transits)-1)]
    for j=0, n_elements(transits)-1 do begin
       phaseup, transits[j], folder=folder, candidate=candidate, /fast, n_peaks=1, lc=lc
       if j eq 0 then begin
          candidates=candidate
          i_best = j
       endif else begin
          candidates = [candidates, candidate]
       end       
    endfor
    i_best = where(candidates.chi eq max(candidates.chi), n_best)
    i_best = i_best[0];i_best[randomu(seed)*n_best]
    transit = transits[i_best]
    candidate = candidates[i_best]
    save, transit, filename=star_dir + folder + 'fepf_guess.idl'
    save, candidate, filename=star_dir + folder + 'fepf_result.idl'
    save, i_best, filename=star_dir + folder + 'how_many_guesses.idl'
    
    mprint, strcompress(/remo, i_best), ' guesses used; found delta chi^2 of ', strcompress(/remo, string(format='(F5.1)', candidate.chi)), '  (trial #', i,')'
    mprint, ' '
    mprint, ' '
    if keyword_set(display) then begin
     plot_transit, transit, lc=lc
     plot_candidate, candidate, lc=lc
     endif
  endfor
  estimate_neit
  END