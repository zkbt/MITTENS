FUNCTION make_dye, t
	logt = alog10(t)
	tmin = 300
	tmax = 1200
	return,(logt - alog10(tmin))/(alog10(tmax) - alog10(tmin))*255.
;	return, (1200 - (t - 300))*255.0/1500.0

END

PRO thesis_sphere, remake=remake, recompile=recompile, bw=bw
	common mearth_tools
	readcol, '~/adopted_mearth_params.csv', j_lspm, j_mass, j_radius, j_distmod, j_source, format='I,D,D,D,A'

; 		for i=0, n_elements(stars)-1 do begin
; 				lspm = stars[i].obs.lspm
;  				i_match = where(j_lspm eq lspm, n_match)
;  				if n_match eq 0 then stop
; 				this = {ra:stars[i].obs.ra, distance:10.0*10^(0.2*(j_distmod[i_match[0]]))}
; 				if n_elements(toplot) eq 0 then toplot = this else toplot = [toplot, this]
; 
; 		endfor		


		if keyword_set(remake) then begin	
	
			if keyword_set(recompile) then begin
				f= file_search('budget_*.idl')
				for i_year=0, n_elements(f)-1 do begin
					restore, f[i_year]
					if i_year eq 0 then allstars = stars else allstars = [allstars, stars]
				endfor
				h = histogram(allstars.obs.lspm, reverse_indices=ri)
				non_overlapping_stars = replicate(stars[0], total(h gt 0))
				total_nobs = fltarr(n_elements(non_overlapping_stars))
				count = 0
				for i=0, n_elements(h)-1 do begin
					if h[i] gt 0 then begin	
						candidate_stars = allstars[ri[ri[i]:ri[i+1]-1]]
						i_max = where(candidate_stars.phased_ps600[2] eq max(candidate_stars.phased_ps600[2]), n_max)
						if n_max gt 1 then i_max = i_max[0]
						non_overlapping_stars[count] = candidate_stars[i_max]
						print_struct, non_overlapping_stars[count].phased
		
						total_nobs[count] = total(candidate_stars.obs.n_goodpointings)
		
						count += 1
		; 				non_overlapping_stars[count].phased.mass = j_mass[i_match]
		; 				non_overlapping_stars[count].phased.radius = j_radius[i_match]
		; 
		; 				jason[i].radius_new = j_radius[i_match]
		; 				jason[i].distance  = 10.0*10^(0.2*(j_distmod[i_match]))
		; 				jason[i].pi  = 1.0/jason[i].distance 
		
					endif
				endfor
		
		
				stars = non_overlapping_stars
				save, filename='stars_with_sensitivity_estimates.idl', stars, REAL_PHASED_SENSITIVITY, REAL_triggered_SENSITIVITY, total_nobs
			endif else restore, 'stars_with_sensitivity_estimates.idl'
	


		
			phased_t50 = fltarr(n_elements(stars), n_elements(radii)) + 1500
			temperature = REAL_PHASED_SENSITIVITY.temp.grid
			!p.multi=[0,1,2]
			interactive = 1
			loadct, 39
			for i=0, n_elements(stars)-1 do begin
				for j=0, n_elements(radii) -1  do begin
					eta_detect = stars[i].phased.temp_detection[*,j]/stars[i].phased.temp_transitprob	; radii is defined in "common mearth_tools" back in mearth.pro
					r_detect = eta_detect/(1-eta_detect)
	
					temperature_range = stars[i].phased.teff*(0.5/a_over_rs(stars[i].phased.mass, stars[i].phased.radius, range(REAL_triggered_SENSITIVITY.period.grid)))^0.5
					i_fit = where(temperature gt min(temperature_range) and temperature lt max(temperature_range) and eta_detect gt 0.25 and eta_detect lt 0.75, n_fit)
	
					if n_fit lt 5 then continue
					fit = linfit(alog(temperature[i_fit]), alog(r_detect[i_fit]), yfit=yfit)
					plot, temperature, r_detect, /xlog, /ylog, yrange=[0.001, 10]
					oplot, temperature, exp(fit[0] + fit[1]*alog(temperature)), color=250
	
					model_r = exp(fit[0] + fit[1]*alog(temperature))
					model_eta = model_r/(1+model_r)
					plot, temperature, eta_detect, yr=[0,1], xrange=[200,1500], title=string(radii[j]) + ', star = ls' + rw(stars[i].obs.lspm)
					oplot, temperature, model_eta, color=250
					this50 = interpol(temperature, model_eta, 0.5)
					if this50 gt max(temperature[i_fit]) or this50 lt 0 then continue
	
					vline, color=50, this50
					xyouts, this50, 0.9, string(this50), charsize=2
				
					phased_t50[i,j] = this50
					if question('asdfgasd?', int=interactive) then stop
		
				endfor
			endfor
	
			triggered_t50 = fltarr(n_elements(stars), n_elements(radii)) + 1500
			temperature = REAL_triggered_SENSITIVITY.temp.grid
			xplot
			loadct, 39
			!p.multi=[0,1,2]
			interactive = 1
			
			loadct, 1
			for i=0, n_elements(stars)-1 do begin
				for j=0, n_elements(radii) -1  do begin
					eta_detect = stars[i].triggered.temp_detection[*,j]/stars[i].triggered.temp_transitprob	; radii is defined in "common mearth_tools" back in mearth.pro
					r_detect = eta_detect/(1-eta_detect)
	
					temperature_range = stars[i].phased.teff*(0.5/a_over_rs(stars[i].phased.mass, stars[i].phased.radius, range(REAL_triggered_SENSITIVITY.period.grid)))^0.5
					i_fit = where(temperature gt min(temperature_range) and temperature lt max(temperature_range) and eta_detect gt 0.25 and eta_detect lt 0.75, n_fit)
	
					if n_fit lt 5 then continue
					fit = linfit(alog(temperature[i_fit]), alog(r_detect[i_fit]), yfit=yfit)
					plot, temperature, r_detect, /xlog, /ylog, yrange=[0.001, 10]
					oplot, temperature, exp(fit[0] + fit[1]*alog(temperature)), color=250
	
					model_r = exp(fit[0] + fit[1]*alog(temperature))
					model_eta = model_r/(1+model_r)
					plot, temperature, eta_detect, yr=[0,1], xrange=[200,1500], title=string(radii[j]) + ', star = ls' + rw(stars[i].obs.lspm)
					oplot,  temperature[i_fit], eta_detect[i_fit], psym=8
					oplot, temperature, model_eta, color=250
					this50 = interpol(temperature, model_eta, 0.5)
					if this50 gt max(temperature[i_fit]) or this50 lt 0 then continue
	
					vline, color=50, this50
					xyouts, this50, 0.9, string(this50), charsize=2
				
					triggered_t50[i,j] = this50
					if question('asdfgasd?', int=interactive) then stop
		
				endfor
			endfor
			save, phased_t50, triggered_t50, stars, total_nobs, filename='thesis_sphere.idl'
		endif else restore, 'thesis_sphere.idl'
		cleanplot

; 		toplot = compile_sample()
; 	;	detect = fltarr(n_elements(toplot))
; 		sens = stars.phased_ps600[2]
; 		prob = stars.phased.TEMP_TRANSITPROB[it]
; 		detect = sens/prob
; 		distance = fltarr(n_elements(stars))
; 		for i=0, n_elements(stars)-1 do begin
; 			i_match = where(toplot.lspm eq stars[i].obs.lspm, n_match)
; 			if n_match eq 1 then distance[i] = toplot[i_match].d else stop
; 		endfor
; ; 		for i=0, n_elements(stars)-1 do begin
; ; 			sens = stars[i].phased_ps600[2]
; ; 			prob = stars[i].phased.TEMP_TRANSITPROB[it]
; ; 			;i_match = where(toplot.lspm eq stars[i].obs.lspm, n)
; ; 			if n eq 1 then detect[i_match] = sens/prob
; ; 		endfor
; 		

		c = compile_sample()
;		toplot[*].distance = c[value_locate(c.lspm, stars.obs.lspm)].d

		sample = struct_conv({lspm:c.lspm, radius:c.radius, mass:c.mass, distance:c.d, v:c.v, k:c.k, ra:c.ra*!pi/180, dec:c.dec*!pi/180})
		sample_phased_t50 = fltarr(n_elements(c), n_elements(radii))+1500
		sample_triggered_t50 = fltarr(n_elements(c), n_elements(radii))+1500
		sample_nobs =  fltarr(n_elements(c), n_elements(radii))
	
		i_match = value_locate(c.lspm, stars.obs.lspm); print, c[i_match].lspm -stars.obs.lspm          
		sample_phased_t50[i_match,*] = phased_t50
		sample_triggered_t50[i_match,*] = triggered_t50

		sample_nobs[i_match] = total_nobs;stars.obs.n_goodpointings

		i_plot = where(sample.distance lt 33 and sample.radius lt 0.35)
		d = max(sample[i_plot].distance)*1.08
			loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65


		set_plot, 'ps'
		radii_to_plot = [4.0, 3.0, 2.7, 2.3, 2.0, 1.8, 1.5, 0.1, 0.0]
		theta = findgen(22)/20*2*!pi
		ROT =!pi/2
		usersym, cos(theta), sin(theta), /fill
		for i_radius=0, n_elements(radii_to_plot)-1 do begin
			this_radius = radii_to_plot[i_radius]
			filename = 'status_hemisphere_'+string(this_radius, form='(F3.1)')+'.eps'
			device, filename=filename, /encapsulated, xsize=12, ysize=12, /inches, /color, /cmyk
			!x.margin = [7,0]+1
			!y.margin = [0,5]+1
			plot, /polar, sample[i_plot].distance, sample[i_plot].ra, psym=8, xs=7, ys=7, xr=d*[-1,1], yr=d*[-1,1], /nodata
			if this_radius ne 0.0 then begin
				loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

				edge = d*1.1
				xyouts, -edge-2, 2+edge-0.1, "The MEarth Project's", charsize=2, charthick=6
				xyouts, -edge-2, 2+edge-2, '50% completeness limit!Cfor planets bigger than', charsize=1.5, charthick=6
				xyouts, -edge-2, 2+edge-7, string(this_radius, form='(F3.1)') + goodtex('R_{'+zsymbol(/earth)+'}'), charsize=4, charthick=6
				xyouts, -edge-2, 2+edge-8.5,goodtex("that transit!C0.1-0.35R_{"+zsymbol(/sun) + "} M dwarfs"),charsize=1.5, charthick=6
			endif
			loadct, 58, file='~/zkb_colors.tbl'
			gray = 150
			theta = findgen(1000)*!pi*2/999.
			r = [10,20,30]
			angle = 60*!pi/180
					loadct, 0, file='~/zkb_colors.tbl'
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			for i=0, n_elements(r)-1 do oplot, cos(theta)*r[i], sin(theta)*r[i], thick=2, color=gray
			off = -1.5
	;		xyouts, (r-off)*cos(angle), (r-off)*sin(angle), orient=90+angle*180/!pi, rw(r) + ' pc', align=0.5, charsize=2, charthick=6, color=255

			dye = fltarr(n_elements(i_plot))+255.
			if this_radius ne 0.0 then for i=0, n_elements(dye)-1 do dye[i] = make_dye(interpol(sample_phased_t50[i_plot[i],*], radii, this_radius))
	;		dye = alog(sample_nobs[i_plot])*255./max(alog(sample_nobs[i_plot]))

	;		dye = (1200 - (sample_phased_t50[i_plot,i_radius] - 300))*254./1500.0
			i_sort = reverse(sort(dye))
			loadct, 67, file='~/zkb_colors.tbl'

			if this_radius eq 0.0 then begin
				loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

				plots, cos(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, sin(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, psym=8, color=200, symsize=0.5
				symsize = sqrt(sample_nobs[i_plot[i_sort]])
				symsize = symsize/max(symsize)*3
				for i=0, n_elements(symsize)-1 do plots, cos(-sample[i_plot[i_sort[i]]].ra+ROT)*sample[i_plot[i_sort[i]]].distance, sin(-sample[i_plot[i_sort[i]]].ra+ROT)*sample[i_plot[i_sort[i]]].distance, psym=8, color=75, symsize=symsize[i]
			endif else begin
				plots, cos(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, sin(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, psym=8, color=dye[i_sort], symsize=1.25
			endelse
			loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

	;		if this_radius eq 0.0 then begin
				xyouts, (r-off)*cos(-angle), (r-off)*sin(-angle), orient=90-angle*180/!pi, rw(r) + ' pc', align=0.5, charsize=2, charthick=15, color=255
				xyouts, (r-off)*cos(-angle), (r-off)*sin(-angle), orient=90-angle*180/!pi, rw(r) + ' pc', align=0.5, charsize=2, charthick=5, color=gray
	;		endif

			loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			angles = indgen(8)*45
			months = ['September', ' ', 'December', ' ', 'March', ' ', 'June', ' ']
			for i=0, n_elements(angles)-1 do xyouts, d*cos(-angles[i]*!pi/180+ROT), d*sin(-angles[i]*!pi/180+ROT), rw(angles[i]*24/360)+'h', charsize=2.3, charthick=5, align=0.5, orient=-(angles[i]+90)+ROT*180/!Pi
			for i=0, n_elements(angles)-1 do xyouts, d*cos(-angles[i]*!pi/180+ROT), d*sin(-angles[i]*!pi/180+ROT), '!C'+months[i], charsize=1.8, charthick=4, align=0.5, orient=-(angles[i]+90)+ROT*180/!Pi, color=100
	
	
	
						loadct, 0, file='~/zkb_colors.tbl'
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			i1214 = where(sample.lspm eq 1186, n1214)
			if n1214 eq 0 then stop
			xpos = cos(-sample[i1214].ra+ROT)*sample[i1214].distance
			ypos =  sin(-sample[i1214].ra+ROT)*sample[i1214].distance
			plots, xpos, ypos, psym=7, thick=7, symsize=2
			xyouts, xpos, ypos-0.35, '!CGJ1214', align=0.5, charsize=1.3, charthick=14, color=255
			xyouts, xpos, ypos-0.35, '!CGJ1214', align=0.5, charsize=1.3, charthick=7

			if this_radius ne 0.0 then begin
				temps = [300,600,900,1200]
				x = fltarr(n_elements(temps)) - edge
				y = edge -18 + findgen(n_elements(temps))*2
				loadct, 67, file='~/zkb_colors.tbl'
				plots, x, y, psym=8, color=make_dye(temps), symsize=2
				xyouts, x, y-0.5, ' ' + string(form='(I4)',temps) + 'K', color =make_dye(temps), charthick=7, charsize=2
			endif else begin
				edge = d*1.1
				nobs = float([100,300,1000,3000])
				symsize = sqrt(nobs)/max(sqrt(sample_nobs[i_plot[i_sort]]))*3
				x = fltarr(n_elements(nobs)) - edge 
				y = edge -10 + findgen(n_elements(nobs))*2
				loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65
				xyouts, -edge-2, 2+edge-0.1, "The MEarth Project's", charsize=2, charthick=6
				xyouts, -edge-2, 2+edge-2, goodtex("observational coverage on!C  0.1-0.35R_{"+zsymbol(/sun) + "} M dwarfs"), charsize=1.5, charthick=6

				for i=0, n_elements(nobs)-1 do plots, x[i]+10, y[i], psym=8, color=75, symsize=symsize[i]
				xyouts, x+10, y-0.5, string(form='(I5)', nobs) + ' obs. =  ', color =75, charthick=6, charsize=1.5, align=1
			endelse

			device, /close
			epstopdf, filename
	endfor

	device, filename='status_hemisphere_legend.eps', /color, xsize=0.7, ysize=.85, /inches
	!x.margin =[1,1]
	!y.margin =[0,1]
			loadct, 67, file='~/zkb_colors.tbl'
;	temps = [300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500]
;	temps = [300,450,600,750,900,1050,1200]
	temps = [300,600,900,1200]
	x = fltarr(n_elements(temps))
	plot, x, temps, /nodata, xs=4, ys=4
	plots, x, temps, psym=8, color=make_dye(temps)
	
	xyouts, x, temps-40, ' ' + string(form='(I4)',temps) + 'K', color =make_dye(temps), charthick=5, charsize=1
	device, /close
	epstopdf, 'status_hemisphere_legend.eps'
stop
END