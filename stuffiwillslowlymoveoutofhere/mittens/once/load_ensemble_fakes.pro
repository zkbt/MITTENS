FUNCTION load_ensemble_fakes, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, period_span=period_span, radius_span=radius_span, depth_span=depth_span, rednoise_span=rednoise_span, randomize=randomize
	common mearth_tools
	common this_star

	f = subset_of_stars(year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, 'fake2/injected_and_recovered.idl')
	if keyword_set(randomize) then f = f[(indgen(n_elements(f)) + randomu(seed)*n_elements(f)) mod n_elements(f)]
	if ~keyword_set(period_span) then period_span = [5,10]
	if ~keyword_set(radius_span) then radius_span = [2.0, 4.0]
	if ~keyword_set(depth_span) then depth_span = [0.005, 0.05]
	if ~keyword_set(n_boxes_span) then n_boxes_span = 3;[0, 100]
	if ~keyword_set(n_sigma_span) then n_sigma_span = [0,100];[0, 100]
	if ~keyword_set(n_sigma_injected_span) then n_sigma_injected_span = [8, 10];[0, 100]
	if ~keyword_set(rednoise_span) then rednoise_span = [0.0, 1.0]
		 ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))

	cleanplot
	xplot
	@psym_circle
	for i=0, n_elements(f)-1 do begin

		restore, f[i] + 'fake2/injected_and_recovered.idl'
		if file_test(f[i] + 'box_pdf.idl') eq 0 then continue
		restore, f[i] + 'box_pdf.idl'
		i_rescale = where(strmatch(priors.name, 'UNCERTAINTY_RESCALING'), n_rescale)
		if n_rescale gt 0 then injected.n_sigma /= priors[i_rescale].coef else stop
		mean_rednoise = mean(sqrt(box_rednoise_variance))
		radius_wanted = injected.radius ge min(radius_span) and injected.radius le max(radius_span)
		i_want = where(radius_wanted, n_want)
		if n_want gt 2 then begin
			injected = injected[i_want]
			recovered = recovered[i_want]
			print, f[i], ', mean rescaling:', string(form='(F4.2)', priors[i_rescale].coef), ', mean rednoise:', string(form='(F4.2)', mean_rednoise)
			j = where(injected.b lt 0.2, nb)
			if stddev(injected.n_sigma) gt 0 and nb gt 1 then begin
		;			plot, injected[j].period, recovered[j].n_sigma/injected[j].n_sigma, psym=3, yr=[0,2]
		;;			hline, mean( recovered[j].n_sigma/injected[j].n_sigma, /nan)
		;			hline, median( recovered[j].n_sigma/injected[j].n_sigma), linestyle=1
					i_nightly = where(strmatch(priors.name, 'NIGHT*'), n_night)
					if n_night eq 0 then stop
					temp = {fraction_of_bls:median( recovered[j].n_sigma/injected[j].n_sigma), info:get_lspm_info(ls[i]), nightly_prior_width:median(priors[i_nightly].uncertainty)/median(injected[j].depth), rednoise:mean_rednoise}
					if n_elements(cloud) eq 0 then cloud = temp else cloud = [cloud, temp]
					if n_elements(cloud) gt 1 then begin
						loadct, 0, /silent
						plot, cloud.nightly_prior_width, cloud.fraction_of_bls, psym=1, /xlog, /nodata
						loadct, 46, /silent, file='~/zkb_colors.tbl'
						plots,  cloud.nightly_prior_width, cloud.fraction_of_bls, color=(cloud.rednoise)*254., psym=8
					endif
		;		if question(/int, 'stop?') then stop
			endif
			
		endif
	endfor
	save, cloud, filename='ensemble_of_blsfractions.idl'
	stop
	loadct, 3
	bin =0.02
	thick=3
	i = where(cloud.rednoise ge 0 and cloud.rednoise lt 0.25, n)
	plothist, cloud[i].fraction_of_bls, bin=bin, /norm, xr=[0,1.5], thick=thick, xtitle=goodtex('(D/\sigma_{MarPLE})/(D_{injected}/\sigma_{injected}) [ratio of recovered-to-injected detection significances]'), ytitle='# of stars'
	vline, linestyle=2, color=0, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.25 and cloud.rednoise le .5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=100, /nan, bin=bin, /norm, thick=thick
	vline, linestyle=2, color=100, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=200, bin=bin, /norm, thick=thick
	vline, linestyle=2, color=200, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.25 and cloud.rednoise le .5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=100, /nan, bin=bin, /norm, thick=thick
	i = where(cloud.rednoise ge 0 and cloud.rednoise lt 0.25, n)
	plothist, cloud[i].fraction_of_bls,  /nan, bin=bin, /norm, thick=thick, /over
	al_legend, /left, /top, color=[0,100,200], goodtex(['< 25% red noise (r_{\sigma, r} < 0.25)', '25-50% red noise (0.25 < r_{\sigma, r} < 0.5)', '> 50% red noise (0.5 < r_{\sigma, r})']), box=0, linestyle=0
	return, cloud
END