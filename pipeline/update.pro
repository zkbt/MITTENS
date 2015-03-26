PRO update, mo, remake=remake
  if keyword_set(mo) then begin
    mprint, 'updating ', mo
  endif else begin
    mo = name2mo(mo_dir())
    mprint, "assuming you're interested in the current star = ", mo
  endelse
  fits_into_lightcurves, mo, remake=remake
  lightcurves_into_marples, mo, remake=remake
  marples_into_origami, mo
  origami_into_candidates, mo
END