PRO refine
	restore, star_dir() + 'cleaned_lc.idl'
	pad = long((max(cleaned_lc.hjd) - min(cleaned_lc.hjd))/0.5)+1

	!mouse.button = 1
	while(!mouse.button lt 2) do begin
		phased_time = (cleaned_lc.hjd - candidate.hjd0)/candidate.period +  pad+ 0.5
		orbit_number = long(phased_time)
		phased_time = (phased_time - orbit_number - 0.5)*candidate.period
		print_struct, candidate
		 n_bins = 6*candidate.period/candidate.duration
		plot_binned, phased_time*24, cleaned_lc.flux, psym=8, yr =( candidate.depth*2 > 3*1.48*mad(cleaned_lc.flux))*[1,-1],  n_bins=n_bins, /sem
		cursor, x, y, /down, /normal
		if y gt 0.75 then candidate.hjd0 += 1.0/60.0/24.0
		if y lt 0.25then candidate.hjd0 -= 1.0/60.0/24.0
		if x gt 0.75 then candidate.period += 1.0/60.0/60.0/24.0
		if x lt 0.25then candidate.period -= 1.0/60.0/60.0/24.0
	endwhile
END