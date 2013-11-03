PRO find_fakes, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, period_span=period_span, radius_span=radius_span, depth_span=depth_span, rednoise_span=rednoise_span, randomize=randomize, n_sigma_span=n_sigma_span
	common mearth_tools
	common this_star

	f = subset_of_stars(year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, 'fake_phased/injected_and_recovered.idl')
	if keyword_set(randomize) then f = f[(indgen(n_elements(f)) + randomu(seed)*n_elements(f)) mod n_elements(f)]
	if ~keyword_set(period_span) then period_span = [5,10]
	if ~keyword_set(radius_span) then radius_span = [2.5]
	if ~keyword_set(depth_span) then depth_span = [0.005, 0.05]
	if ~keyword_set(n_boxes_span) then n_boxes_span = 3;[0, 100]
	if ~keyword_set(n_sigma_span) then n_sigma_span = [0,100];[0, 100]
	if ~keyword_set(n_sigma_injected_span) then n_sigma_injected_span = [8, 10];[0, 100]
	if ~keyword_set(rednoise_span) then rednoise_span = [0.0, 1.0]

	for i=0, n_elements(f)-1 do begin
		restore, f[i] + 'fake_phased/injected_and_recovered.idl'
		if file_test(f[i] + 'box_pdf.idl') eq 0 then continue
		restore, f[i] + 'box_pdf.idl'
		i_rescale = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_rescale)
		if n_rescale gt 0 then injected_n_sigma_rescaled = injected.n_sigma/priors[i_rescale].coef else stop
		mean_rednoise = mean(sqrt(box_rednoise_variance))
		n_sigma_rescaled = recovered.n_sigma ;else stop

		period_wanted = injected.period ge min(period_span) and injected.period le max(period_span)
		radius_wanted = injected.radius ge min(radius_span) and injected.radius le max(radius_span)
		depth_wanted = injected.depth ge min(depth_span) and injected.depth le max(depth_span)
		n_boxes_wanted = recovered.n_boxes ge min(n_boxes_span) and recovered.n_boxes le max(n_boxes_span)
		;n_sigma_wanted = injected_n_sigma_rescaled ge min(n_sigma_injected_span) and injected_n_sigma_rescaled le max(n_sigma_injected_span)
		n_sigma_injected_wanted = injected_n_sigma_rescaled ge min(n_sigma_injected_span) and injected_n_sigma_rescaled le max(n_sigma_injected_span)
		
		n_sigma_wanted = n_sigma_rescaled ge min(n_sigma_span) and n_sigma_rescaled le max(n_sigma_span)

		print, f[i], ', mean rescaling:', string(form='(F4.2)', priors[i_rescale].coef), ', mean rednoise:', string(form='(F4.2)', mean_rednoise)

		i_want = where(period_wanted and radius_wanted and depth_wanted and n_boxes_wanted and n_sigma_injected_wanted and n_sigma_wanted, n_want); and n_sigma_wanted
		if n_want gt 0 and mean_rednoise ge min(rednoise_span) and mean_rednoise le max(rednoise_span) then begin
			print, f[i]
			print_struct, injected[i_want]
			print
			print
			print
			star_dir = f[i] 
			ls = long(stregex(/ext, stregex(/ext, star_dir, 'ls[0-9]+'), '[0-9]+'))
			lspm_info = get_lspm_info(ls)
			which = 0;question('Which would you like to look at?', /num, /int)
			if keyword_set(lspm) then begin
		;		print_struct, recovered[i_want]
				which = question('Which would you like to look at?', /num, /int)
			endif
			restore, f[i] + 'variability_lc.idl'
			cleanplot
			xplot, xsize=1000, ysize=500
			plot, variability_lc.hjd, variability_lc.flux, psym=1, xs=3
			if question(/int, 'check out this fake?') then begin
				fake_pdfs, 1, injected[i_want[which]]
				print, 'this is element ', i_want[which], ' of the array of injected transits'
				print, 'star is: ', star_dir()
				if question(/int, 'MarPLE-plot it?') then marpleplot_displaypdf, /eps
			endif
	;		explore_pdf, /fake
		endif
	endfor
	
END