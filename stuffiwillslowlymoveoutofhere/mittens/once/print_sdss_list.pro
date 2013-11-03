PRO print_sdss_list
  f = long(stregex(file_search('ls*/'), '[0-9]+', /ex))
  for i=0, n_elements(f)-1 do begin
    info = get_lspm_info(f[i])
    print, 'lspm' + strcompress(/remo, f[i]), info.ra, info.dec
  endfor
END 