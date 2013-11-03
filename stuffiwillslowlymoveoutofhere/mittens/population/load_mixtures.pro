FUNCTION load_mixtures, n_eit, year=year, tel=tel
	if keyword_set(year) then ye = string(format='(I02)', year mod 100) else ye = '*'
	if keyword_set(tel) then te = string(format='(I02)', tel mod 100) else te = '*'

  f = file_search('ls*/ye'+ye+'/te'+te+'/blind/best/antitransit_test/single_event_stats.idl')
	if not keyword_set(n_eit) then n_eit = 1

  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  n = n_elements(f)
  restore, f[0]
  s = create_struct('LSPM', 0, gauss_mixture)
  cloud = replicate(s, n)
 x = 0.1*10^((alog10(10000) - alog10(0.1))*findgen(500)/500)
  plot, [0], xrange=[.1, 1000], yrange=[0.0001, 1], /ylog, /xlog
  for i=0, n-1 do begin
    restore, f[i]
    copy_struct, gauss_mixture, s
    cloud[i] = s
    cloud[i].lspm = ls[i]
	oplot,  x, 1-mixed_gauss_cdf(x, 1, gauss_mixture.weights, gauss_mixture.rescalings)^n_eit
  endfor  
	loadct, 39, /silent
	oplot, thick=5, color=250, x, 1-mixed_gauss_cdf(x, 1, [1.,0], [1,1])^n_eit

  return, cloud;[(sort(cloud.lspm))]
END 