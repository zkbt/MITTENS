PRO plot_phased_binned, n_bins=n_bins, psym=psym, med=med
	cleanplot
	xplot
	restore, star_dir() + 'cleaned_lc.idl'
	pad = long((max(cleaned_lc.hjd) - min(cleaned_lc.hjd))/candidate.period) + 1
	phased_time = (cleaned_lc.hjd-candidate.hjd0)/candidate.period + pad + 0.5
	orbit_number = long(phased_time)
	t = (phased_time - orbit_number - 0.5)*candidate.period*24
	if ~keyword_set(n_bins) then n_bins = 4*candidate.period/candidate.duration
	if ~keyword_set(psym) then psym=3
	plot_binned, t, cleaned_lc.flux, n_bins=n_bins, /sem, yr=[1,-1]*(candidate.depth > 3*1.48*mad(cleaned_lc.flux))*2, psym=psym, med=med
;	vline, candidate.duration/2.0*[-1,1]*24, linestyle=1
	fine = (findgen(1000)/999 - 0.5)*candidate.period
	oplot, fine*24, (abs(fine) lt candidate.duration/2.0)*candidate.depth
END