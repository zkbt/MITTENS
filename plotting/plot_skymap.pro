pro plot_skymap, LSPM
	cleanplot
loadct, 0
	device, decomposed=0
	!p.background=255
	!p.color=0
	erase
	common mearth_tools	
;if keyword_set(remake) then begin
;		restore, 'thesis_sphere.idl'

		c = compile_sample()
;
		sample = struct_conv({lspm:c.lspm, radius:c.radius, mass:c.mass, distance:c.d, v:c.v, k:c.k, ra:c.ra*!pi/180, dec:c.dec*!pi/180})
; 		sample_phased_t50 = fltarr(n_elements(c), n_elements(radii))+1500
; 		sample_triggered_t50 = fltarr(n_elements(c), n_elements(radii))+1500
; 		sample_nobs =  fltarr(n_elements(c), n_elements(radii))
; 	
; 		i_match = value_locate(c.lspm, stars.obs.lspm); print, c[i_match].lspm -stars.obs.lspm          
; 		sample_phased_t50[i_match,*] = phased_t50
; 		sample_triggered_t50[i_match,*] = triggered_t50
; 
; 		sample_nobs[i_match] = total_nobs;stars.obs.n_goodpointings
		sample_nobs = ones(n_elements(sample))
		i_plot = where(sample.distance lt 33 and sample.radius lt 0.35)
		d = max(sample[i_plot].distance)*1.08
		loadct, 0
		if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65


	;	set_plot, 'ps'
		radii_to_plot = [0.0]
		theta = findgen(22)/20*2*!pi
		ROT =!pi/2
		usersym, cos(theta), sin(theta), /fill
		for i_radius=0, n_elements(radii_to_plot)-1 do begin
			this_radius = radii_to_plot[i_radius]
			filename = 'status_hemisphere_'+string(this_radius, form='(F3.1)')+'.eps'
		;	device, filename=filename, /encapsulated, xsize=12, ysize=12, /inches, /color, /cmyk
			!x.margin = [2,2];[7,0]+1
			!y.margin = [2,2];[0,5]+1
			plot, /polar, sample[i_plot].distance, sample[i_plot].ra, psym=8, xs=7, ys=7, xr=d*[-1,1], yr=d*[-1,1], /nodata
			if this_radius ne 0.0 then begin
				loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

				edge = d*1.1
; 				xyouts, -edge-2, 2+edge-0.1, "The MEarth Project's", CHARSIZE=1, charthick=6
; 				xyouts, -edge-2, 2+edge-2, '50% completeness limit!Cfor planets bigger than', charsize=1.5, charthick=6
; 				xyouts, -edge-2, 2+edge-7, string(this_radius, form='(F3.1)') + goodtex('R_{'+zsymbol(/earth)+'}'), charsize=4, charthick=6
; 				xyouts, -edge-2, 2+edge-8.5,goodtex("that transit!C0.1-0.35R_{"+zsymbol(/sun) + "} M dwarfs"),charsize=1.5, charthick=6
			endif
			loadct, 58, file='~/zkb_colors.tbl'
			gray = 150
			theta = findgen(1000)*!pi*2/999.
			r = [10,20,30]
			angle = 60*!pi/180
					loadct, 0, file='~/zkb_colors.tbl'
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			for i=0, n_elements(r)-1 do oplot, cos(theta)*r[i], sin(theta)*r[i], thick=1, color=gray
			off = -1.5
	;		xyouts, (r-off)*cos(angle), (r-off)*sin(angle), orient=90+angle*180/!pi, rw(r) + ' pc', align=0.5, CHARSIZE=1, charthick=6, color=255

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
				symsize = symsize/max(symsize)*0.3;*3
			;	for i=0, n_elements(symsize)-1 do plots, cos(-sample[i_plot[i_sort[i]]].ra+ROT)*sample[i_plot[i_sort[i]]].distance, sin(-sample[i_plot[i_sort[i]]].ra+ROT)*sample[i_plot[i_sort[i]]].distance, psym=8, color=75, symsize=symsize[i]
			endif else begin
				plots, cos(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, sin(-sample[i_plot[i_sort]].ra+ROT)*sample[i_plot[i_sort]].distance, psym=8, color=dye[i_sort], symsize=1.25
			endelse
			loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

	;		if this_radius eq 0.0 then begin
				xyouts, (r-off)*cos(-angle), (r-off)*sin(-angle), orient=90-angle*180/!pi, rw(r) + ' pc', align=0.5, CHARSIZE=1, charthick=3, color=255
				xyouts, (r-off)*cos(-angle), (r-off)*sin(-angle), orient=90-angle*180/!pi, rw(r) + ' pc', align=0.5, CHARSIZE=1, charthick=1, color=gray
	;		endif

			loadct, 0
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			angles = indgen(8)*45
			months = ['September', ' ', 'December', ' ', 'March', ' ', 'June', ' ']
			for i=0, n_elements(angles)-1 do xyouts, d*cos(-angles[i]*!pi/180+ROT), d*sin(-angles[i]*!pi/180+ROT), rw(angles[i]*24/360)+'h', CHARSIZE=0.8, charthick=1, align=0.5, orient=-(angles[i]+90)+ROT*180/!Pi
			for i=0, n_elements(angles)-1 do xyouts, d*cos(-angles[i]*!pi/180+ROT), d*sin(-angles[i]*!pi/180+ROT), '!C'+months[i], charsize=1, charthick=1, align=0.5, orient=-(angles[i]+90)+ROT*180/!Pi, color=100
	
	
	
						loadct, 0, file='~/zkb_colors.tbl'
				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65

			IF KEYWORD_SET(LSPM) THEN BEGIN
				i1214 = where(sample.lspm eq lspm[0], n1214)
				if n1214 eq 0 then stop
				xpos = cos(-sample[i1214].ra+ROT)*sample[i1214].distance
				ypos =  sin(-sample[i1214].ra+ROT)*sample[i1214].distance
				xyouts, xpos, ypos-0.35, '!CLSPM'+string(form='(I04)', lspm), align=0.5, charsize=2, charthick=5, color=255
				xyouts, xpos, ypos-0.35, '!CLSPM'+string(form='(I04)', lspm), align=0.5, charsize=2, charthick=1
				plots, xpos, ypos, psym=8, thick=2, symsize=1

			ENDIF
; 			if this_radius ne 0.0 then begin
; 				temps = [300,600,900,1200]
; 				x = fltarr(n_elements(temps)) - edge
; 				y = edge -18 + findgen(n_elements(temps))*2
; 				loadct, 67, file='~/zkb_colors.tbl'
; 				plots, x, y, psym=8, color=make_dye(temps), symsize=2
; 				xyouts, x, y-0.5, ' ' + string(form='(I4)',temps) + 'K', color =make_dye(temps), charthick=1.5, CHARSIZE=1
; 			endif else begin
; 				edge = d*1.1
; 				nobs = float([100,300,1000,3000])
; 				symsize = sqrt(nobs)/max(sqrt(sample_nobs[i_plot[i_sort]]));*3
; 				x = fltarr(n_elements(nobs)) - edge 
; 				y = edge -10 + findgen(n_elements(nobs))*2
; 				loadct, 0
; 				if keyword_set(bw) then loadct, file='~/zkb_colors.tbl', 65
; 				xyouts, -edge-2, 2+edge-0.1, "The MEarth Project's", CHARSIZE=1, charthick=6
; 				xyouts, -edge-2, 2+edge-2, goodtex("observational coverage on!C  0.1-0.35R_{"+zsymbol(/sun) + "} M dwarfs"), charsize=1.5, charthick=6
; 
; 				for i=0, n_elements(nobs)-1 do plots, x[i]+10, y[i], psym=8, color=75, symsize=symsize[i]
; 				xyouts, x+10, y-0.5, string(form='(I5)', nobs) + ' obs. =  ', color =75, charthick=1, charsize=1.5, align=1
; 			endelse


 		endfor
	

END