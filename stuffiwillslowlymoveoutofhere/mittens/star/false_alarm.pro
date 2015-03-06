FUNCTION g, x
  return, (0.5 + 0.5*erf(double(x)/sqrt(2)))  
END

FUNCTION false_alarm,  folder
  common this_star
  common mearth_tools
  mprint, doing_string, 'estimating false alarm probability for ', star_dir + folder
  if not keyword_set(folder) then folder = ''
  if is_uptodate(star_dir + folder + 'antitransit_test/single_event_stats.idl', star_dir + 'medianed_lc.idl') eq 0 then begin
    mprint, tab_string, 'single event stats are out of date!'
    characterize_single_events, folder
  endif
  restore, star_dir + folder + 'antitransit_test/single_event_stats.idl'
  restore, star_dir + folder + 'candidate.idl'
    if file_test(star_dir + 'eit/n_eit.idl') eq 0 then begin
      mprint, tab_string, 'no EIT found! using'
      n_eit = 300000 
     endif else  restore, star_dir + 'eit/n_eit.idl'

 ; single_test = mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)
  if keyword_set(display) then begin
    if keyword_set(deltachi) then x = sqrt(deltachi)*1.5*findgen(100)/100 else x = 8*findgen(100)/100 
    single_test = mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)
    gaussian_test = g(x)
    cdf = single_test^n_eit
    gcdf = gaussian_test^n_eit
    fap = 1.0d - cdf
    xplot, 14, title=star_dir + ' | probability of false alarm'
    plot, thick=3, x^2, 1.0-cdf,  /ylog, yrange=[.001,1], xtitle=goodtex('\Delta\chi^2'), ytitle='False Alarm Probability', ys=3
    oplot, thick=3, x^2, 1.0-gcdf, linestyle=2
 endif
  if keyword_set(deltachi) then begin
    p_fa = 1.0-mixed_gauss_cdf(sqrt(deltachi), 1, gauss_mixture.weights, gauss_mixture.rescalings)^n_eit
    vline, deltachi
    hline, p_fa
    return, p_fa
  endif
  ; ccdf = 1.0-mixed_gauss_cdf(biglogspacedx, 1, [1.0-10^p[0], 10^p[0]],[p[1], p[1]*p[2]])

END