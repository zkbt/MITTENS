PRO eps, on=on, off=off
  common mearth_tools
  if not keyword_set(on) and not keyword_set(off) then eps = eps eq 0
  
  if keyword_set(on) then eps = 1
  if keyword_set(off) then eps = 0
  tf = ['false', 'true']
  if keyword_set(verbose) then begin
    printl
    print, '   eps?     = ', tf[eps]
    printl
  endif
END