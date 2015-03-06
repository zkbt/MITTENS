FUNCTION randomls
  f = file_search('ls*/')
  ls = stregex(/ext, f, '[0-9]+')
  n = n_elements(ls)
  return, ls[randomu(seed)*n]
END