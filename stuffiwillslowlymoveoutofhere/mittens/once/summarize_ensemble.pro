PRO summarize_ensemble
	common mearth_tools
	; plot the priors generated from the season long fits
	restore, working_dir + 'ensemble_priors.idl'
	erase
	tags = tag_names(ensemble_priors)
	set_plot, 'ps'
	device, filename='ensemble_priors.eps', /encap, /inches, xsize=9, ysize=7
	smultiplot, /init, [1, n_tags(ensemble_priors)], ygap=0.01
	for j=0, n_tags(ensemble_priors)-1 do begin
		smultiplot
		m = where(ensemble_priors.(j).coef ne 0 and ensemble_priors.(j).uncertainty ne 0, n_nonzero)
		if n_nonzero gt 1 then ploterror, ytitle=tags[j], m, ensemble_priors[m].(j).coef, ensemble_priors[m].(j).uncertainty, psym=8, xs=3, symsize=.8, charsize=0.8, yr=((1.48*mad(ensemble_priors[m].(j).coef)*[-1,1]*8 + median(ensemble_priors[m].(j).coef))> min(ensemble_priors[m].(j).coef)) < max(ensemble_priors[m].(j).coef), ys=3
	endfor
	smultiplot, /def
	device, /close
	epstopdf, 'ensemble_priors'
END