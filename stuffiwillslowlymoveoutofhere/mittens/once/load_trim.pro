FUNCTION load_trim
	common mearth_tools
	f = file_search('*/*/*/raw_trimmed.idl')
	restore, f[0]
	n_data = fltarr(n_elements(f))
	cloud = replicate(n_rejected, n_elements(f))
	for i=0, n_elements(f)-1 do begin 
		restore, f[i]
		n_data[i] = n_datapoints
		cloud[i] = n_rejected
	endfor
loadct, 39

erase
	tags = tag_names(cloud)
	!p.charsize=1.3
	plot, [0], /nodata, xr=[0, 1], yr=[1, 1000], /ylog, xs=3, xtitle='Fraction of Raw Data Points Rejected (%)', ytitle='# of stars'
	for i=0, n_tags(cloud)-1 do begin
		
		print, string(form='(A20)', tags[i]), string(format='(F8.3)', total(cloud.(i))/total(n_data)*100), ' %'
		if stddev(cloud.(i)) eq 0 then continue
		plothist, cloud.(i)/n_data, xr=[0,1], bin=0.1, thick=3, xs=3, /ylog, /over, color=i*255./n_tags(cloud)
	endfor
	legend, tags, color = indgen(n_tags(cloud))*255.0/n_tags(cloud)	, /top, /right, box=0, linestyle=0, thick=4, margin=5
	return, cloud
END