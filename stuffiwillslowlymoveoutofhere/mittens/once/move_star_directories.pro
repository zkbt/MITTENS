PRO move_star_directories
  @mearth_dirs
  f = file_search('stars/tel*lspm*/', /mark_dir)
  for i=0, n_elements(f)-1 do begin
    lspm = long(stregex(stregex(f[i], 'lspm[0-9]+', /ex), '[0-9]+', /ex))
    tel = uint(stregex(stregex(f[i], 'tel[0-9]+', /ex), '[0-9]+', /ex))    
    year = 2010
    ls_string = 'ls'+string(format='(I04)', lspm)
    te_string = 'te' + string(format='(I02)', tel)
    ye_string = 'ye' + string(format='(I02)', year mod 2000)
    star_dir = ls_string + '/' + ye_string + '/' + te_string + '/'
    print, f[i] ,' > ', star_dir
    file_mkdir, star_dir
    file_copy, f[i]+'*', star_dir + '.', /verbose, /recursive, /overwrite
  endfor
END