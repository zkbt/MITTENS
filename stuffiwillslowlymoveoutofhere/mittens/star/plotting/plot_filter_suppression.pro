PRO plot_filter_suppression, tel, lspm
	@mearth_dirs
	@generate_star_dir
	@psym_circle
	!p.charsize=0.8
	f = file_search(star_dir + 'fakes_b/*_filtered.idl')
	if f[0] ne '' then begin
		set_plot, 'ps'
		device, filename=star_dir + 'filter_suppression.eps', /encapsulated, /color, xsize=10, ysize=5, /inches
		for i=0, n_elements(f)-1 do begin
			restore, f[i]
			
			if n_elements(filt) eq 0 then filt = filtered else filt = [filt, filtered]
			restore, strmid(f[i], 0, strpos(f[i], 'filtered')) + 'fake.idl'
			if n_elements(fakes) eq 0 then fakes = fake else fakes = [fakes, fake]
	
			if n_elements(i_fake) eq 0 then i_fake = intarr(n_elements(filtered)) + i else i_fake = [i_fake,  intarr(n_elements(filtered)) + i]
		endfor
		
		sorted_fakes = fakes[sort(fakes.radius)]
		i_radii = uniq(sorted_fakes.radius)
		radii = sorted_fakes[i_radii].radius
		n_radii = n_elements(radii)
		radii_color =  (1+indgen(n_radii))*254.0/n_radii;radii^2/max(radii^2)*254.0

		restore, star_dir + 'target_lc.idl'
		restore, star_dir + 'medianed_lc.idl'
		noise_min = median(target_lc.fluxerr)

		multiplot, [3, 1], /init, xgap=0.03
		multiplot
		!y.range=[max(filt.fake), min(filt.fake)]
		!y.range[1] = max([!y.range[1], -0.1])
		!x.range=[0, max(filt.model)]
		!y.style = 3
		!x.style = 3
		loadct, 39
		
		color = (1+value_locate(radii, fakes[i_fake].radius))*254.0/n_radii;fakes[i_fake].radius^2/max(fakes.radius^2)*254.0
		plot, psym=8, symsize=0.5, filt.model, filt.fake, ytitle='Raw (mag.)', /nodata, xtitle='Injected (mag.)'
		oplot, [0,1],[0,1], linestyle=1
		hline, stddev(target_lc.flux)
		hline,noise_min, linestyle=2


		plots, filt.model, filt.fake, color=color, psym=8, symsize=0.5

		n_detect = fltarr(n_radii)
		n_total = fltarr(n_radii)
		noise_this = stddev(target_lc.flux)
 		for i=0, n_radii-1 do begin
			this = where(fakes[i_fake].radius eq radii[i])
 			i_deepenough = where(filt[this].model gt noise_min, n_deepenough)
			if n_deepenough eq 0 then return
			n_total[i] = n_deepenough
			n_detect[i] = total(filt[this[i_deepenough]].fake gt noise_this) 			
 		endfor
		legend, box=0, 'R=' + string(format='(F3.1)', radii) + ': ' + strcompress(/remo, string(format='(I2)', 100*n_detect/n_total)) + goodtex('\pm') + strcompress(/remo, string(format='(I2)', 100*sqrt(n_detect)/n_total)) +'%', psym=8 + fltarr(n_radii), color=radii_Color, /bottom, /left


		multiplot
		plot, psym=8, symsize=0.5, filt.model, filt.fake_filtered, /nodata, xtitle='Injected (mag.)', ytitle='Filtered (mag.)', title=star_dir
		oplot, [0,1],[0,1], linestyle=1
		hline, stddev(medianed_lc.flux)
		hline, median(target_lc.fluxerr), linestyle=2
		plots, filt.model, filt.fake_filtered, color=color , psym=8, symsize=0.5
		n_detect = fltarr(n_radii)
		n_total = fltarr(n_radii)
		noise_this = stddev(medianed_lc.flux)
 		for i=0, n_radii-1 do begin
			this = where(fakes[i_fake].radius eq radii[i])
 			i_deepenough = where(filt[this].model gt noise_min, n_deepenough)
			n_total[i] = n_deepenough
			n_detect[i] = total(filt[this[i_deepenough]].fake_filtered gt noise_this) 			
 		endfor
		legend, box=0, 'R=' + string(format='(F3.1)', radii) + ': ' + strcompress(/remo, string(format='(I2)', 100*n_detect/n_total)) + goodtex('\pm') + strcompress(/remo, string(format='(I2)', 100*sqrt(n_detect)/n_total)) + '%', psym=8 + fltarr(n_radii), color=radii_Color, /bottom, /left

		multiplot
		plot, psym=8, symsize=0.5, filt.model, filt.difference, ytitle='Hypothetical Difference (mag.)', xtitle='Injected Decrement (mag.)', /nodata
		oplot, [0,1],[0,1], linestyle=1
		plots, filt.model, filt.difference, color=color , psym=8, symsize=0.5
	
		multiplot, /def
		!x.style=0
		!y.style=0
		!y.range=0
		!x.range=0
		device, /close
		epstopdf, star_dir + 'filter_suppression'
		set_plot, 'x'

	endif
END
	