PRO update, mo
  if keyword_set(mo) then begin
    mprint, 'updating ', mo
  endif else begin
    mo = name2mo(mo_dir())
    mprint, "assuming you're interested in the current star = ", mo
  endelse
  fits_into_lightcurves, mo
  lightcurves_into_marples, mo
  marples_into_origami, mo
  origami_into_candidates, mo
END