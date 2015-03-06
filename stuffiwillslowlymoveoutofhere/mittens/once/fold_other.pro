PRO fold_other, eps=eps
	for i=0,1 do begin
		if i eq 0 then type = 'tfa.lc' else type = 'epd.lc'
		readcol, type, format='D,I,D,D,D,D,D,D,I', hjd, id, mag1, err_mag1, mag2, err_mag2,mag3,err_mag3,accepted
	
		lc = struct_conv({hjd:hjd-2400000.5d, flux:mag1- median(mag1), fluxerr:err_mag1, okay:accepted})
		
		restore, '/pool/eddie1/zberta/mearth_most_recent/ls2986/combined/cleaned_lc.idl'
	
	;	lc.flux = median_filter(lc.hjd, lc.flux, filtering_time = 1.0)
			cleanplot
	
		if keyword_set(eps) then begin
			set_plot, 'ps'
			filename=type + 'test.eps'
			device, filename=filename, xsize=10, ysize=6, /inches, /color, /encap
		endif else 		xplot, ysize=600, xsize=1000
	
	
		!mouse.button = 1
		while(!mouse.button lt 2) do begin
	
			!x.range=[-0.5, 0.5]
	
			phased_mearth = cleaned_lc
			phase = ((cleaned_lc.hjd - candidate.hjd0)/candidate.period) mod 1
			phase = ((phase + 1.5) mod 1)-0.5
			phased_mearth.hjd = phase*candidate.period
		
		
			phased_hat = lc
			phase = ((lc.hjd - candidate.hjd0)/candidate.period) mod 1
			phase = ((phase + 1.5) mod 1)-0.5
			phased_hat.hjd = phase*candidate.period
		
	
			loadct, 39
			smultiplot, /init, [1,3], ygap=0.02
			smultiplot
			ploterror, phased_mearth.hjd, phased_mearth.flux, phased_mearth.fluxerr, yr=[0.02, -0.02], psym=8, title=type + ', P = ' + rw(string(candidate.period)) + ' days?', ytitle='Flux (mag.)'
		
			dye = long(lc.hjd - min(lc.hjd))/(max(lc.hjd)-min(lc.hjd))*254*10 mod 255
			smultiplot
			plot, phased_hat.hjd, phased_hat.flux, yr=[0.02, -0.02], psym=1, /nodata, ytitle='Flux (mag.)'
			plots, phased_hat.hjd, phased_hat.flux, psym=1, color=dye, noclip=0
		
			smultiplot
			plot, phased_hat.hjd, phased_hat.flux, yr=[0.02, -0.02], psym=1, /nodata, xtitle='Phased Time (days)', ytitle='Flux (mag.)'
			plots, phased_hat.hjd, phased_hat.flux, psym=1, color=dye, noclip=0
			oplot, phased_mearth.hjd, phased_mearth.flux, psym=8
		
			print_struct, candidate
			smultiplot, /def
	
			if keyword_set(eps) then !mouse.button = 2 else begin
				cursor, x, y, /down, /normal
		
				if y gt 0.75 then candidate.hjd0 += 1.0/60.0/24.0
				if y lt 0.25then candidate.hjd0 -= 1.0/60.0/24.0
				if x gt 0.75 then candidate.period += 5.0/60.0/60.0/24.0
				if x lt 0.25then candidate.period -= 5.0/60.0/60.0/24.0
				erase
			endelse
		endwhile
		if keyword_set(eps) then begin
			device, /close
			set_plot, 'x'
			epstopng, filename, /hide
		endif
	endfor
END