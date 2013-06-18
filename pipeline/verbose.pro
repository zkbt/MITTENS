PRO verbose, on=on, off=off
  common mearth_tools
  if not keyword_set(on) and not keyword_set(off) then verbose = verbose eq 0
  
  if keyword_set(on) then verbose = 1
  if keyword_set(off) then verbose = 0
  tf = ['false', 'true']
  if keyword_set(verbose) then begin
    printl
    print, '   verbose?     = ', tf[verbose]
    printl
  endif
  
END