PRO test_lc, filename, n_sigma=n_sigma, n_trim=n_trim, pause=pause, bad_hjd
	;dir = '/pool/barney0/mearth/lightcurves/'
	;tel_string = 'tel0' + string(tel, format='(I1)')
	;filename = dir+tel_string+'/' + target_name+'_lc.fits'
	f = mrdfits(filename, 1, h, status=status)
	erase
	if (status ge 0) then begin
		i_target = where(f.class eq 9)	
		i_target = i_target[0]
		n_obs = n_elements(f[i_target].hjd)
		i_friends = where(f.class eq -1 and f.weight[0] gt 0 and abs(f.medflux - f[i_target].medflux) lt 1.0, n_friends)

		max_rows = 15
		if (n_friends ge n_trim) then begin	
			n_rows = min([n_friends+1, max_rows])
			multiplot, /init, [0,2, n_rows, 0, 1]
			print, filename
		
			j_left = where(f[i_target].ha lt 0, n_left)
			print, n_left, ' out of ', n_obs, ' observations on one side of the meridian'
			if (n_left gt 0) then begin
				medflux_left = median(f[i_friends].flux[j_left], dimension=1)
				flux_left = f[i_friends].flux[j_left] - (fltarr(n_left) + 1.0)#medflux_left
				scatter_left = 1.48*median(abs(flux_left), dimension=1)
				hjd_left = f[i_friends].hjd[j_left]
				left_bad = abs(flux_left/((fltarr(n_left) + 1.0)#scatter_left)) gt n_sigma
				left_trim = total(left_bad, 2) ge n_trim
				multiplot & plot, f[i_target].flux[j_left] - f[i_target].medflux, psym=5, /yno, title=filename
				if (total(left_trim)) then begin
					oplot, where(left_trim),  f[i_target].flux[j_left[where(left_trim)]] - f[i_target].medflux, psym=5, color=250
					if keyword_set(bad_hjd) then bad_hjd = [[[bad_hjd[*,0], f[i_target].hjd[j_left[where(left_trim)]]], [bad_hjd[*,1], f[i_target].hjd[j_left[where(left_trim)]+1 < n_obs]]]] else bad_hjd = [[[f[i_target].hjd[j_left[where(left_trim)]]], [f[i_target].hjd[j_left[where(left_trim)]+1 < n_obs]]]]
				endif
				for i=0, n_rows-2 do begin
					multiplot & plot, flux_left[*,i], psym=1, /yno
					if (total(left_bad[*,i])) then oplot,where(left_bad[*,i]), flux_left[where(left_bad[*,i]), i], psym=1, color=250
				endfor
			endif
	
			j_right = where(f[i_target].ha gt 0, n_right)
			print, n_right, ' out of ', n_obs, ' observations on the other side'

			if (n_right gt 0) then begin
				medflux_right = median(f[i_friends].flux[j_right], dimension=1)
				flux_right = f[i_friends].flux[j_right] - (fltarr(n_right) + 1.0)#medflux_right
				scatter_right = 1.48*median(abs(flux_right), dimension=1)
				hjd_right = f[i_friends].hjd[j_right]
				right_bad = abs(flux_right/((fltarr(n_right) + 1.0)#scatter_right)) gt n_sigma
				right_trim = total(right_bad, 2) ge n_trim
				multiplot & plot, f[i_target].flux[j_right] - f[i_target].medflux, psym=5, /yno, title=filename
				if (total(right_trim)) then begin
					oplot, where(right_trim),  f[i_target].flux[j_right[where(right_trim)]] - f[i_target].medflux, psym=5, color=250
					if keyword_set(bad_hjd) then bad_hjd = [[[bad_hjd[*,0], f[i_target].hjd[j_right[where(right_trim)]]], [bad_hjd[*,1], f[i_target].hjd[j_right[where(right_trim)]+1 < n_obs]]]] else bad_hjd = [[[f[i_target].hjd[j_right[where(right_trim)]]], [f[i_target].hjd[j_right[where(right_trim)]+1 < n_obs]]]]
				endif
				for i=0, n_rows-2 do begin
					multiplot & plot, flux_right[*,i], psym=1, /yno
					if (total(right_bad[*,i])) then oplot,where(right_bad[*,i]), flux_right[where(right_bad[*,i]), i], psym=1, color=250
				endfor
			endif
			wait, pause
			multiplot, /default
		endif				
	endif
END
