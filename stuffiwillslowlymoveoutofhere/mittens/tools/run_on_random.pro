
PRO run_on_random, loop=loop
  f = file_search('ls*/*/')
  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
    n = n_elements(ls)
  if not keyword_set(loop) then loop=1
  for j=0, loop-1 do begin
    i = randomu(seed)*n
    update_star, ls[i], ye[i], te[i]
    jenkins_bootstrap
  endfor
END