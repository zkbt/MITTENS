PRO characterize_single_events, candidate_folder, eps=eps

  common this_star
  common mearth_tools
  if keyword_set(candidate_folder) then begin
    folder = candidate_folder + 'antitransit_test/'
  endif else folder = 'antitransit_test/'
  mprint, doing_string, 'characterizing single events for ', star_dir + folder
  file_mkdir, star_dir + folder
  
  restore, star_dir + 'target_lc.idl'
  if keyword_set(candidate_folder) then begin
    restore, star_dir + candidate_folder + 'candidate.idl'
     i_intransit = where_intransit(target_lc, candidate, n_intransit, i_oot=i_oot, buffer=20.0/60.0/24.0)
     target_lc[i_intransit].okay = 0
     mprint, string(format='(I10)', n_intransit), ' points clipped as being in-transit'
  endif
  
  clean_lightcurve, /antitransit_test, folder=folder, target_lc=target_lc, medianed_lc=medianed_lc

;  restore, star_dir + folder + 'medianed_lc.idl'
  antitransit = find_the_transit(medianed_lc, /all, threshold=0.0, deltachi_start=deltachi_start)
  x = sqrt(deltachi_start)  
  anti_ccdf = ccdf(x)

  xmin = interpol(anti_ccdf.x, anti_ccdf.y, 0.1);max(x)/10;median(x);min(x) > 0.1
  xmax = interpol(anti_ccdf.x, anti_ccdf.y, 3.0/n_elements(x))

  i = where(anti_ccdf.y gt 0 and anti_ccdf.x ge xmin)
  n = 50
  logspacedx = xmin*10.0d^((alog10(xmax) - alog10(xmin))*findgen(n)/(n))
  logspacedy = interpol(anti_ccdf.y[i], anti_ccdf.x[i], logspacedx)
 if keyword_set(display) then  loadct, 0, /silent
  

  ; two distributions!
  expression = '1.0-mixed_gauss_cdf(x, 1, [1.0-10^p[0], 10^p[0]],[p[1],p[1]*p[2]])'
  initial_guess = [-1, 1.0, 5.0]

  pi = replicate({fixed:0, limited:[0,0], limits:[0.D, 0.D], step:0.0}, 3)
  pi[0].limited=[1,1]
  pi[0].limits=[-5d,0d]
 ; pi[0].step=0.1
  pi[1].limited=[1,1]
  pi[1].limits=[0.5d, 5.0d]
  ;pi[1].fixed = 1
 ; pi[1].step=.001
  pi[2].limited=[1,1]
  pi[2].limits=[1.0d, 10.0d]  
 ; pi[2].step=1.0  
  
  p = mpfitexpr(expression, logspacedx, logspacedy, logspacedy/100, initial_guess, parinfo=pi, status=status, /quiet) 
  biglogspacedx = 0.1*10^((alog10(10000) - alog10(0.1))*findgen(500)/500)
 
   if keyword_set(display) or keyword_set(eps) then begin
     if keyword_set(eps) then begin
      set_plot, 'ps'
      filename=star_dir + 'plots/' + 'single_events.eps'
      device, filename=filename, /encap, /color, /inches, xsize=4, ysize=4
  
          !x.thick=4
          !y.thick=4
          !p.charthick=4
     endif else begin
        xplot, 13, xsize=200, ysize=200,  title=star_dir + ' | single anti-transit statistics'    
        cleanplot, /silent
        xplot, 13, xsize=200, ysize=200, title=star_dir + ' | single anti-transit statistics'    
        endelse
        plot, anti_ccdf.x^2, anti_ccdf.y, yrange=[0.0001,1.0], /ylog, /xlog, xrange=[xmin,xmax>100], xtitle=goodtex('\Delta\chi^2 of Single "Antitransit" Events'), ytitle='False Alarm Probability'
oploterror, anti_ccdf.x^2, anti_ccdf.y, anti_ccdf.y/100
        oplot, logspacedx^2, logspacedy, psym=8
        oplot, thick=3, biglogspacedx^2, 1.0-mixed_gauss_cdf(biglogspacedx, 1, [1.0-10^p[0], 10^p[0]],[p[1], p[1]*p[2]]) 
        oplot, thick=3, anti_ccdf.x^2, 1.0-mixed_gauss_cdf(anti_ccdf.x, 1, [1.0],[1.0]), linestyle=1
     if keyword_set(eps) then begin
       device, /close
       set_plot, 'x'
       epstopdf, filename
    endif
  endif
  gauss_mixture = {weights:[1-10^p[0], 10^p[0]], rescalings:[p[1], p[1]*p[2]]}
mprint, '                         gaussian mixture weights =', gauss_mixture.weights
mprint, '                          gaussian mixture scales =', gauss_mixture.rescalings

  save, gauss_mixture, filename=star_dir + folder + 'single_event_stats.idl'  

END