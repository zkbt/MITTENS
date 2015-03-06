PRO plot_pdf_spectrum, dir=dir, octopus=octopus, candidate=candidate

	if keyword_set(octopus) then begin
		f = file_info(dir + "boxes_all_durations.txt.bls")
		if f.size gt 1d7 then begin
	;		if question('PDF spectrum file size is '+ string(f.size, form='(G20.3e3)')   + '; are you sure you want to open it?', /int) eq 0 then
	 return
		endif
		octopus = read_ascii(dir + "boxes_all_durations.txt.bls")
		n_durations = n_elements(octopus.(0)[*,0]) - 1
		periods = octopus.(0)[0,*]
		multiduration_SN = octopus.(0)[1:n_durations, *]
		sn = multiduration_SN[0,*]

		plot, 1.0/periods, sn, /nodata, xstyle=3, xtitle='Frequency (inverse days)', xtick_get=xtick_get, /noerase, ytitle=goodtex('D/\sigma'), yr=[0, max(multiduration_SN, /nan) > 10]
		for i=0, n_durations-1 do begin
			sn = multiduration_SN[i,*]
			i_finite = where(finite(sn))
			oplot, 1.0/periods, sn, color=i*254./n_durations		
	;		plots, peak_candidates[i,*].period, peak_candidates[i,*].depth/ peak_candidates[i,*].depth_uncertainty, psym=4, symsize=4, color=150, thick=2
		endfor
	endif else begin
			restore, dir + 'spectrum_pdf.idl'
			periods = p_min*exp(max_misalign/data_span*dindgen(n_periods))
			!y.range=0
			plot, 1.0/periods, squashed_sn, xstyle=3, xtitle='Frequency (inverse days)', xtick_get=xtick_get, /noerase, ytitle=goodtex('D/\sigma')
	endelse
	axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F6.3)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)'
	if n_elements(candidate) gt 0 then plots, 1/candidate.period, candidate.depth/candidate.depth_uncertainty, psym=8, color=250

END