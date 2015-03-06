PRO load_fits
	f = subset_of_stars('spliced_clipped_season_fit.idl') 
	tags = ['MERID', 'COMMON_MODE', 'SEE']
	restore, f[0]+ 'spliced_clipped_season_fit.idl'
	template = create_struct('star_dir', '', spliced_clipped_season_fit[0])
	n_tags = n_elements(tags)
	n = n_elements(f)
	cloud = replicate(template, [n, n_tags])

	restore, f[0] + 'rednoise_pdf.idl'
	rednoise = fltarr(n, n_elements(box_rednoise_variance))
	for i=0, n-1 do begin
		restore, f[i]+ 'spliced_clipped_season_fit.idl'
		for j=0, n_tags-1 do begin
			match = where(spliced_clipped_season_fit.name eq tags[j], n_match)
			if n_match gt 0 then begin
				copy_struct, spliced_clipped_season_fit[match], template
				cloud[i,j]=template	
				cloud[i,j].star_dir = f[i]
			endif
		endfor
		restore, f[i]+ 'rednoise_pdf.idl'
		rednoise[i,*] = box_rednoise_variance
	endfor

i = where(cloud.name eq 'COMMON_MODE' and strmatch(cloud.star_dir, '*ye10*'))
ploterror, cloud[i].coef, cloud[i].uncertainty, psym=8

cleanplot
loadct, 39
xplot, /top, xsize=1500

	common mearth_tools
	ye_strings = 'ye'+string(format='(I02)', possible_years mod 100)
	!p.multi=[0,2+n_elements(ye_strings),n_tags]
	for j=0, n_tags-1 do begin
		for i=0, n_elements(ye_strings)-1 do begin
			i_year = where(cloud.name eq tags[j] and strmatch(cloud.star_dir, '*'+ye_strings[i]+'*'))
			if i eq 0 then plothist, cloud[i_year].coef, bin=0.001, /nodata, xr=[-0.02, 0.02], title=tags[j]
			plothist, cloud[i_year].coef, bin=0.001, /over, linestyle=i, thick=3
		endfor
		al_legend, /top, /left, linestyle=indgen(n_elements(ye_strings)), ye_strings, thick=3
		for i=0, n_elements(ye_strings)-1 do begin
			i_year = where(cloud.name eq tags[j] and strmatch(cloud.star_dir, '*'+ye_strings[i]+'*'))
			if i eq 0 then plothist, abs(cloud[i_year].coef/cloud[i_year].uncertainty), bin=0.5, /nodata, title=tags[j], /nan
			plothist, abs(cloud[i_year].coef/cloud[i_year].uncertainty), bin=0.5, /over, linestyle=i, thick=3, /nan
		endfor
		al_legend, /top, /left, linestyle=indgen(n_elements(ye_strings)), ye_strings, thick=3

		for i=0, n_elements(ye_strings)-1 do begin
			i_year = where(cloud.name eq tags[j] and strmatch(cloud.star_dir, '*'+ye_strings[i]+'*'))
			plot_binned, cloud[i_year].coef, median(rednoise, dim=2), psym=8, title=ye_strings[i] + ' - '+ tags[j]
		endfor
	endfor
	stop
END
				
		