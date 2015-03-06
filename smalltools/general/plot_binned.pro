PRO plot_binned, x, y, yerr, yno=yno, psym=psym, xrange=xrange, yrange=yrange, xstyle=xstyle, ystyle=ystyle, xtitle=xtitle, ytitle=ytitle, title=title, charsize=charsize, n_bins=n_bins, overplot=overplot, justbins=justbins, errcolor=errcolor, thick=thick, quartile=quartile, color=color, symsize=symsize, sem=sem, med=med, hatlen=hatlen, binwidth=binwidth, xtickunits=xtickunits, subset=subset

	if ~keyword_set(xrange) then xrange = range(x)
	if ~keyword_set(yrange) then yrange = range(y)

	if not keyword_set(n_bins) then n_bins = 20
	if keyword_set(binwidth) then n_bins = (max(xrange) - min(xrange))/binwidth
	binned = replicate({x:0.0d, mean:0.0d, scatter:0.0d, n:0L}, n_bins)
	if ~keyword_set(binwidth) then binwidth = (max(xrange) - min(xrange))/n_bins
	binned.x = dindgen(n_bins)*binwidth+ min(xrange) + binwidth/2.0
	i_sort = sort(x)
	binsize = n_elements(x)/n_bins
	for i=0, n_bins-1 do begin 
		if keyword_set(irregular) then begin
			i_inbin = i_sort[i*binsize:(i+1)*binsize-1 < n_elements(x)] 
			n_inbin = n_elements(i_inbin)
			binned[i].x = mean(x[i_inbin])
		endif else begin
			i_inbin = where(x ge binned[i].x - binwidth/2.0d and x le binned[i].x + binwidth/2.0d, n_inbin)
	;		print, n_inbin
		endelse
		if n_inbin gt 0 then begin
			if n_inbin gt 1 then begin
				if keyword_set(sem) then begin
					if keyword_set(med) then binned[i].mean = median(y[i_inbin]) else binned[i].mean = mean(y[i_inbin])
					binned[i].scatter = stddev(y[i_inbin])/sqrt(n_inbin -1)
				endif else begin
					binned[i].mean = mean(y[i_inbin])
					binned[i].scatter = stddev(y[i_inbin]) ;1.48*mad(y[i_inbin])
				endelse
			endif else if n_elements(yerr) gt 0 and n_inbin ge 1 then begin
				binned[i].mean = y[i_inbin]
				binned[i].scatter = yerr[i_inbin]
			endif
		endif
		if keyword_set(quartile) and n_inbin gt 2 + keyword_set(med) then begin
			tophalf = where(y[i_inbin] ge median(y[i_inbin]), n_tophalf)
			bottomhalf = where(y[i_inbin] le median(y[i_inbin]), n_bottomhalf)
			if n_tophalf gt 0 and n_bottomhalf gt 0 then begin
				binned[i].mean = (median(y[i_inbin[tophalf]]) + median(y[i_inbin[bottomhalf]]))/2.0
				binned[i].scatter = (median(y[i_inbin[tophalf]]) - median(y[i_inbin[bottomhalf]]))/2.0
			endif
		endif
		binned[i].n = n_inbin
		
	endfor
	if keyword_set(fixerr) then binned.scatter  = fixerr

	if ~keyword_set(overplot) then plot, x, y, yno=yno, psym=psym, xrange=xrange, yrange=yrange, xstyle=xstyle, ystyle=ystyle, xtitle=xtitle, ytitle=ytitle, title=title, /nodata, charsize=charsize, xtickunits=xtickunits
	if n_elements(color) le 1 then color = 150
	if n_elements(subset) eq 0 then subset = n_elements(x)
	i_shuffle = sort(randomu(seed, n_elements(x)))
	if ~keyword_set(justbins) then plots, psym=psym, x[i_shuffle[0:subset-1]], y[i_shuffle[0:subset-1]], color=color, noclip=0, symsize=symsize
	i = where(binned.scatter ne 0, n)
	if ~keyword_set(thick) then thick=3
	if n gt 0 then oploterror, binned[i].x, binned[i].mean, binned[i].scatter, thick=thick, psym=3, errcolor=errcolor, errthick=thick, hatlen=hatlen
;	print_struct, binned
END