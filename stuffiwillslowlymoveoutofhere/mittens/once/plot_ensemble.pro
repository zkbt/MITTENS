PRO plot_ensemble
	; plot the priors generated from the season long fits
	restore, working_dir + 'ensemble_priors.idl'
	erase
	smultiplot, /init, [1, n_elements(tags)], ygap=0.01
	for j=0, n_elements(tags)-1 do begin
		k = where(strmatch(priors.name, tags[j]), n_match)
		if n_match eq 1 then begin
			ensemble_priors[i].(j).coef = priors[k].coef
			ensemble_priors[i].(j).uncertainty = priors[k].uncertainty
		endif
		smultiplot
		m = where(ensemble_priors.(j).coef ne 0 and ensemble_priors.(j).uncertainty ne 0, n_nonzero)
		if n_nonzero gt 1 then ploterror, ytitle=tags[j], m, ensemble_priors[m].(j).coef, ensemble_priors[m].(j).uncertainty, psym=8, xs=3, yr=((1.48*mad(ensemble_priors[m].(j).coef)*[-1,1]*7 + median(ensemble_priors[m].(j).coef))> min(ensemble_priors[m].(j).coef)) < max(ensemble_priors[m].(j).coef), ys=3
	endfor
	smultiplot, /def
END