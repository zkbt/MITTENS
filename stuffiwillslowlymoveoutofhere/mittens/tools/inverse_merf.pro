FUNCTION g, x
  return, (0.5 + 0.5*erf(double(x)/sqrt(2)))  
END

FUNCTION inverse_merf, p_fa, folder=folder, gauss=gauss
  common this_star
  common mearth_tools
  if not keyword_set(folder) then folder = 'blind/best/'

  doing_string = tab_string + tab_string + doing_string
  tab_string = tab_string + tab_string + tab_string
  
  mprint, doing_string, 'estimating deltachi cutoff from FAP'
  if is_uptodate(star_dir + folder + 'antitransit_test/single_event_stats.idl', star_dir + 'medianed_lc.idl') eq 0 then begin
    mprint, tab_string, 'single event stats are out of date!'
    characterize_single_events, folder
  endif
  restore, star_dir + folder + 'antitransit_test/single_event_stats.idl'
 
    if file_test('eit_coef.idl') eq 0 then fit_eit
    restore, 'eit_coef.idl'
    restore, star_dir  + folder  + 'search_parameters.idl' 	
    n_eit = exp(eit_coef.const + eit_coef.n_data*alog(search_parameters.n_data) + eit_coef.n_periods*alog(search_parameters.n_periods))
    mprint, tab_string, 'effective independent tests = ', strcompress(/remo, n_eit)
	 
	 @mearth_strings
	 
 ; single_test = mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)
    x = 1
    if keyword_set(gauss) then begin
      while(mixed_gauss_cdf(x, 1, [1,0],[1,1])^n_eit lt 1.0-p_fa) do x+=1
    endif else begin
      while(mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)^n_eit lt 1.0-p_fa) do x+=1
    endelse
    cutoff = x^2
;    if keyword_set(gauss) then single_test = mixed_gauss_cdf(x, 1, 1, 1) else single_test = mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)
;    cdf = single_test^n_eit
;;    fap = 1.0d - cdf
;;    cutoff = interpol(x, fap, p_fa)^2
;    if keyword_set(display) then begin
;      xplot, 14, title=star_dir + ' | probability of false alarm'
;      cleanplot, /silent
;      xplot, 14, title=star_dir + ' | probability of false alarm'
;      loadct, 0, /silent
;      plot, thick=3, x^2, 1.0-cdf,  /ylog, yrange=[.001,1], xtitle=goodtex('\Delta\chi^2'), ytitle='False Alarm Probability', ys=3
;      hline, p_fa
;      vline, cutoff
;    endif
;  mprint, tab_string, done_string
  return, cutoff
  
  ; ccdf = 1.0-mixed_gauss_cdf(biglogspacedx, 1, [1.0-10^p[0], 10^p[0]],[p[1], p[1]*p[2]])

END