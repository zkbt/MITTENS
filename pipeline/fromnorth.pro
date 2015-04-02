PRO fromnorth
  common mearth_tools
  desired_mo = mo_ensemble[reverse(sort(mo_ensemble.dec))].mo
  for i=0, n_elements(desired_mo)-1 do begin
    update, desired_mo[i]
  endfor
END