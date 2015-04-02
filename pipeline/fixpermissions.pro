PRO fixpermissions
  f = file_search('mo*')
  for i=0, n_elements(f)-1 do begin
    set_star, f[i]
    mittens_permissions
  endfor
END