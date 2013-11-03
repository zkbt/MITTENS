FUNCTION estimate_pfa, candidate, candidate_folder

  common this_star
  common mearth_tools
  if keyword_set(candidate_folder) then begin
    folder = candidate_folder + 'antitransit_test/'
  endif else folder = 'antitransit_test/'
  old_tab_string = tab_string
  old_doing_string = doing_string
  doing_string = tab_string + doing_string

  tab_string = tab_string + tab_string
  
  mprint, doing_string, 'characterizing single events for ', star_dir + folder
  file_mkdir, star_dir + folder
  
  restore, star_dir + 'target_lc.idl'
  if keyword_set(candidate_folder) then begin
    i_intransit = where_intransit(target_lc, candidate, n_intransit, i_oot=i_oot)
    target_lc[i_intransit].okay = 0
    mprint, string(format='(I10)', n_intransit), ' points clipped as being in-transit'
  endif
  ;save, target_lc, filename=star_dir + folder + 'target_lc.idl'
  
  mprint, tab_string, 'cleaning an inverted, transit-clipped light curve'
  clean_lightcurve, /antitransit_test, folder=folder, target_lc=target_lc, medianed_lc=medianed_lc

;  restore, star_dir + folder + 'medianed_lc.idl'
  antitransit = find_the_transit(medianed_lc, /all, threshold=0.0, deltachi_start=deltachi_start)
  deltachi_start = 
  anti_ccdf = ccdf(sqrt(deltachi_start))

  posdeltachi = deltachi_start[where(deltachi_start gt 0)]
  xmin = median(posdeltachi) 
  xmax = max(anti_ccdf.x)

  i = where(anti_ccdf.y and anti_ccdf.x gt xmin)
  n = 50
  logspacedx = xmin*10^((alog10(xmax) - alog10(xmin))*findgen(n)/n)
  logspacedy = interpol(anti_ccdf.y[i], anti_ccdf.x[i], logspacedx)
  loadct, 0, /silent
  

  ; two distributions!
  expression = '1.0-mixed_gauss_cdf(x, 1, [1.0-10^p[0], 10^p[0]],[p[1],p[1]*p[2]])'
  initial_guess = [-1, 1.0, 50.0]

  pi = replicate({fixed:0, limited:[0,0], limits:[0.D, 0.D], step:0.0}, 3)
  pi[0].limited=[1,1]
  pi[0].limits=[-5d,0d]
 ; pi[0].step=0.1
  pi[1].limited=[1,1]
  pi[1].limits=[0.1d, 5.0d]
 ; pi[1].step=.001
  pi[2].limited=[1,1]
  pi[2].limits=[1.0d, 1000.0d]  
 ; pi[2].step=1.0  
  
  mprint, tab_string, 'fitting the CCDF of single antitransit statistics'
  p = mpfitexpr(expression, logspacedx, logspacedy,logspacedy/10, initial_guess, parinfo=pi, status=status, /quiet) 
  biglogspacedx = 0.1*10^((alog10(10000) - alog10(0.1))*findgen(500)/500)
 
   if keyword_set(display) then begin
    xplot, 13, xsize=600, ysize=400, title=star_dir + ' | single anti-transit statistics'    
    plot, anti_ccdf.x^2, anti_ccdf.y, yrange=[0.0001,1.0], /ylog, /xlog, xrange=[xmin,max(anti_ccdf.x)], xtitle=goodtex('\Delta\chi^2'), ytitle='False Alarm Probability'
    oplot, logspacedx^2, logspacedy, psym=8
    oplot, thick=3, biglogspacedx^2, 1.0-mixed_gauss_cdf(biglogspacedx, 1, [1.0-10^p[0], 10^p[0]],[p[1], p[1]*p[2]]) 
    oplot, thick=3, anti_ccdf.x^2, 1.0-mixed_gauss_cdf(anti_ccdf.x, 1, [1.0],[1.0]), linestyle=1
  endif
  gauss_mixture = {weights:[1-10^p[0], 10^p[0]], rescalings:[p[1], p[1]*p[2]]}
  if keyword_set(display) then print_struct, struct_conv(gauss_mixture)
  
  save, gauss_mixture, filename=star_dir + folder + 'single_event_stats.idl'  
  tab_string = old_tab_string
  doing_string = old_doing_string
  mprint, tab_string, done_string

  
END