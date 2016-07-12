PRO checkstatus, name
  common mearth_tools
  mo = name2mo(name)
  match = where(progress.mo EQ mo, nmatch)
  if nmatch eq 0 then begin
    print, "UH-OH! couldn't find progress info on ", name
    print, "  (perhaps try its 2MASS-like MEarth ID?)"
  endif else begin
    print, "Time elapsed since processing steps (in days):"
    set_star, mo
    print_struct, progress[match]
    mprint, "   (filenames = identifed whether new files have appeared for this star)"
    mprint, "   (lightcurves = ingested from FITS to IDL)"
    mprint, "   (marples = individual marples calculated from light curves)"
    mprint, "   (periodic = last time phase-folded search was run)" 
  endelse
END