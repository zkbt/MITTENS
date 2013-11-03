PRO loop_lc, random=random
  f = file_search('ls*/ye*/te*/medianed_lc.idl')
    n = n_elements(f)
  f = f[(randomu(seed)*n + indgen(n)) mod n]
  
   if keyword_set(random) then f = f[ (indgen(n) + uint(randomu(seed)*n)) mod n]
  
  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))

  for i=0, n-1 do begin
    set_star, ls[i], ye[i], te[i]
 ;   estimate_sensitivity, /rem
;    plot_sensitivity
;    estimate_sensitivity, /gauss,/rem
   ; plot_sensitivity, /gauss
    
    print
    print, f[i]
    print, 'directory # ', strcompress(/remo, i), '/', strcompress(/remo, n)
    print
    ;plot_sin
	print_star
    ;wait, 1
  ;  if question('eps?') then plot_sin, /eps
  endfor

END