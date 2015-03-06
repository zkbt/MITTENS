PRO plot_star, eps=eps, email=email, pdf=pdf
common this_star
  common mearth_tools
  
  if keyword_set(eps) then file_mkdir, star_dir +'plots/'
  restore, star_dir + 'medianed_lc.idl'
  restore, star_dir + 'ext_var.idl'
  restore, star_dir + 'superfit.idl'
  restore, star_dir + 'target_lc.idl'
  display, /on
  xplot, xpos=1000, ypos=0

  plot_lightcurves, /time, eps=eps, pdf=pdf
 ; plot_superfit, superfit, eps=eps

	if file_test(star_dir + 'blind/best/candidate.idl') then begin
  restore, star_dir + 'blind/best/candidate.idl'
		; plot_candidate, candidate;, eps=eps
		
		;plot_events, candidate
		plot_candidate, candidate, eps=eps, n_lc=3
		characterize_single_events, 'blind/best/';, eps=eps
		
		fap = merf(candidate, 'blind/best/');, eps=eps)
			printl
			print_bls, email=email
			printl
		if not keyword_set(eps) and keyword_set(interactive) then begin
			intransit_images
			plot_events, /diag, n_lc=2
		endif
	endif

 if keyword_set(eps) then spawn, 'gzip -fv '+star_dir +'plots/*.eps'
END
