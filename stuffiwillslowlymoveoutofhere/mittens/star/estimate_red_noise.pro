PRO estimate_red_noise
  common this_star
  if is_uptodate(star_dir + 'polyfit_red_noise.idl', star_dir + 'medianed_lc.idl') then begin
    print, ' - estimate of red noise is up to date'
    return
  endif
  print, ' - estimating red noise for ' + star_dir
  if file_test(star_dir + 'medianed_lc.idl') eq 0 then return
  restore, star_dir + 'medianed_lc.idl'
  if file_test(star_dir + 'blind_transits.idl') then restore, star_dir + 'blind_transits.idl'
  i_it = where_intransit(medianed_lc, transits, i_oot=i_oot, n_it, buffer=10.0/60.0/24.0)
  lc = medianed_lc[i_oot]
  
  ; duration range to consider
  min_duration = 0.01
  max_duration = 0.25
  duration_bin = 0.01
  n_durations = (max_duration - min_duration)/duration_bin
  durations = findgen(n_durations)*duration_bin + min_duration

	print, 'testing the red noise for ' + star_dir
	for i=0, n_elements(durations)-1 do begin
		if n_elements(sigmas) eq 0 then sigmas = pont_v(lc, durations[i], /no_plot) else sigmas = [[sigmas],  [pont_v(lc, durations[i], /no_plot)]]
	endfor
	print, 'finished testing red noise'

  i = where(finite(/nan, sigmas[0,*]), n_nan)
  if n_nan gt 0 then sigmas[0,i] = 5.0 < (mean(sigmas[0,*], /nan) > 0.5)
  
  i = where(finite(/nan, sigmas[1,*]), n_nan)
  if n_nan gt 0 then sigmas[1,i] = 5.0 < (mean(sigmas[1,*], /nan) > 0)
  
  degree = 5
  white = poly_fit(durations, sigmas[0,*], degree)
  red = poly_fit(durations, sigmas[1,*], degree)
;  white = svdfit(durations, reform(sigmas[0,*]), degree, func='flegendre')  
;  red = svdfit(durations, reform(sigmas[1,*]), degree, func='flegendre')

  if keyword_set(eps) then begin
    set_plot, 'ps'
    device, filename=star_dir + 'polyfit_red_noise.eps', /encapsulated, /color, /inches, xsize=7.5, ysize=5
  endif 
    loadct, 39, /silent
    plot, durations*24, sigmas[0,*], xtitle='Expected Transit Duration (hours)', ytitle='Normalized Red and White Noise', xstyle=3, ystyle=3, yrange=[0 < min(sigmas), max(sigmas) > 1], thick=1
    oplot, durations*24, poly(durations, white), thick=4
    oplot, durations*24, sigmas[1,*], color=250, thick=1
    oplot, durations*24, poly(durations, red), color=250, thick=4

  if keyword_set(eps) then begin
    device, /close
    set_plot, 'ps'
    spawn, 'convert -density 72 ' + star_dir + 'red_noise.eps ' + star_dir + 'red_noise.png&'
  endif
  


	red = {white:white, red:red}
	save, red, filename=star_dir + 'polyfit_red_noise.idl'
END
