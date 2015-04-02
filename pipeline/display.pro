PRO display, on=on, off=off
  common mearth_tools
  if not keyword_set(on) and not keyword_set(off) then display = display eq 0
  
  if keyword_set(on) then display = 1
  if keyword_set(off) then display = 0
  tf = ['false', 'true']
  ;if keyword_set(verbose) then begin
  if 0:
    printl
    print, '   plotting?     = ', tf[display]
    printl
  endif
END