PRO test_cm, night, observatory, eps=eps, n_nights=n_nights, nights=nights, squashed=squashed, nomark=nomark, event=event
; demonstrate the common mode, in one succinct plot
;marpleplot_cmdemo, nights=55987.0d +[0,2,5,7,9], /eps

	common mearth_tools
	
	if keyword_set(event) then begin
		night = event.hjd - mearth_timezone()
	endif
	if keyword_set(nights) then begin
		xspan = [min(nights), max(nights)+1]  + mearth_timezone() - 0.5
		n_nights = n_elements(nights)
		night = min(nights)
	endif else begin
		if ~keyword_set(n_nights) then n_nights = 1
		 nights = night + indgen(n_nights)
		xspan = night + mearth_timezone() - 0.5 + [0, n_nights]
	endelse 

	file_mkdir, star_dir() + 'plots/'
	filename = star_dir() + 'plots/cmdemo'+rw(night)+'.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		if keyword_set(squashed) then device, filename=filename, /encap, xsize=4, ysize=1.5, /inches, /color else device, filename=filename, /encap, xsize=7.5*n_nights/2, ysize=2, /inches, /color

	endif
	!p.charsize=0.6
	!x.margin=[11,2]
	if ~keyword_set(n_nights) then n_nights = 3

	caldat, 2400000l + night, m, d, y
	str = strcompress(/remo, y) + '-' + strcompress(/remo, m) + '-' + strcompress(/remo, d)

	f = file_search('mo*/combined/cleaned_lc.idl')
	if f[0] eq '' then begin
		print, 'NO LIGHT CURVES FOUND!'
		return
	endif

		std = fltarr(n_elements(f))
		for i=0, n_elements(f)-1 do begin
			restore, f[i] 
			std[i] = stddev(cleaned_lc.flux);1.48*mad(cleaned_lc.flux)
		endfor
		f = f[reverse(sort(std))]

	yrange=[0.035, -0.025]
	smultiplot, /init, [n_nights, 1], xgap=0.0025

	cm = load_common_mode(observatory)
	
	for j=0, n_nights-1 do begin
		caldat, 2400000l + nights[j] , m, d, y
		str = strcompress(/remo, y) + '-' + strcompress(/remo, m) + '-' + strcompress(/remo, d)

		smultiplot
		xrange=[-5,6.25]
		loadct, 0
		if j eq 0 then ytitle='Relative Flux (mag.)!C!D[and common mode correction]' else ytitle=''
		if j eq fix((n_nights-1)/2) then xtitle = 'Time from Midnight (hours)' else xtitle=''
		plot,[0], xrange=xrange, ys=3, /nodata, yrange=yrange, xs=3, xtitle=xtitle, ytitle=ytitle
		counter = 0
		counterobs =0



		for i=0, n_elements(f)-1 do begin
		
			star_dir = stregex(/extr, f[i], mo_prefix + mo_regex + '/combined/')
			restore, star_dir + 'inflated_lc.idl'
			restore, star_dir + 'cleaned_lc.idl'
			restore, star_dir + 'variability_lc.idl'
			varfree_lc = inflated_lc
			varfree_lc.flux = inflated_lc.flux -interpol(variability_lc.flux - cleaned_lc.flux, variability_lc.hjd, inflated_lc.hjd)
			h = histogram(bin=xspan[1] - xspan[0], min=xspan[0], max=xspan[1], varfree_lc.hjd, reverse_indices=ri)
			if h[0] gt 1 then begin

				
				mo = name2mo(star_dir)
				info = get_mo_info(mo)
			
				lc = varfree_lc[ri[ri[0]:ri[0+1]-1]]
;				lc.flux -= median(lc.flux)
				restore,  star_dir + '/ext_var.idl'
				ext_var = ext_var[ri[ri[0]:ri[0+1]-1]]
				lc.hjd = 24*(lc.hjd - mearth_timezone() - nights[j])
				q = where(lc.hjd gt xrange[0] and lc.hjd lt xrange[1], n_q)
				if n_q gt 0 then begin
					loadct, /silent,  43, file='~/zkb_colors.tbl'
					weight =1.0/(lc[q].fluxerr> 0.001)^2
					maxweight = 1.0/0.001^2
					color =weight/maxweight*255 < 255;(info.radius)/.35*255;
					theta = findgen(21)/20*2*!pi
					usersym, cos(theta), sin(theta), thick=1
					plots, lc[q].hjd,lc[q].flux, psym=8, symsize=0.1 , color=color, noclip=0
					plots, lc[q].hjd,lc[q].flux, symsize=0.5 , color=color, noclip=0, linestyle=0, thick=1
					if n_elements(stars) eq 0 then stars =  star_dir else stars = [star_dir, stars] 
					print, star_dir, h
					counter += 1
					counterobs += n_q
				endif
			endif


		endfor
		
		if keyword_set(event) then begin
				center = 24*(event.hjd - mearth_timezone() - nights[j])
				width = 24*event.duration
				depth = event.depth
				x = [min(xrange), center-width/2, center-width/2, center+width/2, center+width/2, max(xrange)]
				y = [0, 0, depth, depth, 0, 0]
				loadct, file='~/zkb_colors.tbl', 58, /silent
				oplot, x, y, thick=2, color=150
		endif
		
		loadct, 0
		h = histogram(bin=xspan[1] - xspan[0], min=xspan[0], max=xspan[1],cm.mjd_obs, reverse_indices=ri)
		if h[0] gt 0 then begin
			cm_this = cm[ri[ri[0]:ri[0+1]-1]]
			usersym, cos(theta), sin(theta), thick=3
			cm_x = (cm_this.mjd_obs-nights[j] - mearth_timezone())*24
			q = where(cm_x gt xrange[0] and cm_x lt xrange[1], n_q)
			if n_q gt 0 then begin
				oploterror,cm_x[q], cm_this[q].flux, cm_this[q].fluxerr, thick=2, hatlen=100
				n = n_elements(stars)
			endif
			xyouts, mean(xrange), yrange[1]+0.002, '!C' + rw(counter) + ' M dwarfs; ' + rw(counterobs) + ' obs.',  charsize=0.5, align=0.5
			xyouts, mean(xrange), yrange[0]-0.002, str, charsize=0.8, align=0.5, charthick=2
		endif



	endfor





	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
END
