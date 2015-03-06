PRO phase_trigger, date
  common this_star

  ; find  the best individual transits
  printl
  print, ' - phasing up a known event for ' + star_dir
  printl
  
  if file_test(star_dir + 'medianed_lc.idl') eq 0 then begin
    print, "     !@%!% couldn't find a clean light curve to use!
    return
  endif
  
  if not keyword_set(date) then begin
    print, "   + would you like to see J's triggers?"
    response = strarr(1)
    read, response
    if strmatch(response, '*y*', /fold_case) then  begin
	if strmatch(!version.os, '*Mac*') then spawn, 'open http://mearth.sao.arizona.edu/cgi-bin/detect.cgi?object='+stregex(/ex, star_dir, 'tel[0-9]+lspm[0-9]+'); else spawn, 'firefox http://mearth.sao.arizona.edu/cgi-bin/detect.cgi?object='+stregex(/ex, star_dir, 'tel[0-9]+lspm[0-9]+') + ' &'
    endif
    ; get user input for date
    date = strarr(1)
    printl
    print, '   + please specify anchor date here'
    read, date
    printl
  endif
  
  
  marked_mjd = double(date_conv(date[0], 'M') + 7.0/24.0)
  restore, star_dir + 'medianed_lc.idl'
  restore, star_dir + 'ext_var.idl'

  marked_hjd = interpol(medianed_lc.hjd, ext_var.mjd_obs, marked_mjd)
  
  i_night = where(abs(medianed_lc.hjd - marked_hjd) lt 8.0/24.0, n_night)
  if n_night eq 0 then begin
    print, "      (*!#% there weren't any points on the night of ", marked_hjd
    return
  endif
  transits = find_the_transit(medianed_lc, threshold=1.0, /all)
;  ; plot the guess at the transit
  i = where(abs(transits.hjd0 - marked_hjd) eq min(abs(transits.hjd0 - marked_hjd)), n)

  transit = transits[i]
  
  print, '   identified transit offset by ', string(format='(F6.1)', (transit.hjd0 - marked_hjd)*24), ' hours from chosen point' 
  plot_lightcurves, 1, /time, transit=transit, wtitle=star_dir + ' | best initial guess | HJDo (fixed to) ' + string(transit.hjd0, format='(F9.3)') + ' = ' + date_conv(transit.hjd0+2400000.5d - 7.0/24.0, 'S')

  folder = 'trigger/'
  file_mkdir, star_dir + folder
  phaseup, transit, n_lc=n_lc, n_peaks=n_peaks, folder=folder, candidate=candidate
  plot_candidate, candidate
  plot_events, candidate
  
END