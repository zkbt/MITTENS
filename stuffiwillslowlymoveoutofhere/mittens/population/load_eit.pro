FUNCTION load_eit
  f = file_search('ls*/ye*/te*/eit/n_eit.idl')
  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  n = n_elements(f)
  restore, f[0]
  restore, make_star_dir(ls[0], ye[0], te[0])+ 'eit/1/search_parameters.idl'
  s = create_struct('LSPM', 0, 'N_EIT', 0.0D,  search_parameters)
  cloud = replicate(s, n)

  for i=0, n-1 do begin
  restore, f[i]
  restore, make_star_dir(ls[i], ye[i], te[i])+ 'eit/1/search_parameters.idl'
    
    copy_struct, search_parameters, s
    cloud[i] = s
    cloud[i].lspm = ls[i]
    cloud[i].n_eit = n_eit
  endfor  
  cloud = cloud[where(cloud.n_data gt 0)]
  return, cloud;[(sort(cloud.lspm))]
END 

