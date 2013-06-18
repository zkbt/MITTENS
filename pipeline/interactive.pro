PRO interactive, on=on, off=off
  common mearth_tools
  if not keyword_set(on) and not keyword_set(off) then interactive = interactive eq 0
  
  if keyword_set(on) then interactive = 1
  if keyword_set(off) then interactive = 0
  tf = ['false', 'true']
  if keyword_set(verbose) then begin
    printl
    print, ' interactive?     = ', tf[interactive]
    printl
  endif
END