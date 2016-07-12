PRO update, mo, remake=remake, origami=origami, all=all
  if keyword_set(all) then begin
    desired_mo = mo_ensemble[sort(mo_ensemble.dec)].mo
    for i=0, n_elements(desired_mo)-1 do begin
      update, desired_mo[i], remake=remake, origami=origami
    endfor
  end

  if keyword_set(mo) then begin
    mprint, 'updating ', mo
  endif else begin
    mo = name2mo(mo_dir())
    mprint, "assuming you're interested in the current star = ", mo
  endelse
  fits_into_lightcurves, mo, remake=remake
  lightcurves_into_marples, mo, remake=remake
  if keyword_set(origami) then begin
    marples_into_origami, mo
    origami_into_candidates, mo
  endif
END
