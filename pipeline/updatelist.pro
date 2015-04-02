PRO updatelist, filename
  readcol, filename, mos, format='a'
  for i=0, n_elements(mos)-1 do begin
    update, mos[i]
  endfor
END