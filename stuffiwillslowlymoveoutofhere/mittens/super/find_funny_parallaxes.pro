FUNCTION find_funny_parallaxes, jason, i_bad=i_bad
;	restore, 'jason_temp.idl'
	old = struct_conv(get_lspm_info(jason.lspm))
	v = old.v
	k = old.k
	j = old.j
	restore, '2011_obs_summary.idl'
	medflux = fltarr(n_elements(k))
	for i=0, n_elements(medflux) -1 do begin
		i_match = where(obs_summary.lspm eq jason[i].lspm, n_match)
		if n_match gt 0 then medflux[i] = mean(obs_summary[i_match].medflux) else print, 'sad trombone for ', jason[i].lspm
	endfor
	nomedflux = medflux eq 0

	!p.multi=[0,3,2]
	!p.charsize=2
	!y.range = [0, 13]
	dm = 5*alog10(1.0/jason.pi_literature/10.0)
	abs_k = k - dm
	i_fit = where(finite(abs_k) and abs_k gt 0 and abs_k lt 20 )
	vk_fit = poly_fit(v[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=vk_ms)
	ik_fit = poly_fit(medflux[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=ik_ms)
	jk_fit = poly_fit(j[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=jk_ms)

	i_ok = i_fit[where(abs_k[i_fit] - vk_ms lt 3*1.48*mad(abs_k[i_fit] - vk_ms)  and  abs_k[i_fit] - ik_ms lt 3*1.48*mad(abs_k[i_fit] - ik_ms)  and  abs_k[i_fit] - jk_ms lt 3*1.48*mad(abs_k[i_fit] - jk_ms) , complement=i_bad)]
	i_bad = i_fit[i_bad]

	plot, v[i_ok]-k[i_ok], abs_k[i_ok], xtitle='V-K', ytitle='absolute K', psym=3, title='Literature', xr=[3,10]
	oplot,v[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, v[i_fit]-k[i_fit], vk_ms, psym=8, symsize=2, color=250

	plot, medflux[i_ok]-k[i_ok], abs_k[i_ok], xtitle='medflux-K', ytitle='absolute K', psym=3, title='Literature', xr=[1,6]
	oplot,medflux[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, medflux[i_fit]-k[i_fit], ik_ms, psym=8, symsize=2, color=250

	plot, j[i_ok]-k[i_ok], abs_k[i_ok], xtitle='J-K', ytitle='absolute K', psym=3, title='Literature',  xr=[0.6,1.4]
	oplot,j[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, j[i_fit]-k[i_fit], jk_ms, psym=8, symsize=2, color=250

	dm = 5*alog10(jason.distance/10.0)
	abs_k = k - dm
	i_fit = where(finite(abs_k) and abs_k gt 0 and abs_k lt 20 )
	vk_fit = poly_fit(v[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=vk_ms)
	ik_fit = poly_fit(medflux[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=ik_ms)
	jk_fit = poly_fit(j[i_fit]-k[i_fit], abs_k[i_fit], 2, yfit=jk_ms)

	i_ok = i_fit[where(abs_k[i_fit] - vk_ms lt 3*1.48*mad(abs_k[i_fit] - vk_ms)  and  abs_k[i_fit] - ik_ms lt 3*1.48*mad(abs_k[i_fit] - ik_ms)  and  abs_k[i_fit] - jk_ms lt 3*1.48*mad(abs_k[i_fit] - jk_ms) , complement=i_bad)]
	i_bad = i_fit[i_bad]

	plot, v[i_ok]-k[i_ok], abs_k[i_ok], xtitle='V-K', ytitle='absolute K', psym=3, title='Literature', xr=[3,10]
	oplot,v[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, v[i_fit]-k[i_fit], vk_ms, psym=8, symsize=2, color=250

	plot, medflux[i_ok]-k[i_ok], abs_k[i_ok], xtitle='medflux-K', ytitle='absolute K', psym=3, title='Literature', xr=[1,6]
	oplot,medflux[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, medflux[i_fit]-k[i_fit], ik_ms, psym=8, symsize=2, color=250

	plot, j[i_ok]-k[i_ok], abs_k[i_ok], xtitle='J-K', ytitle='absolute K', psym=3, title='Literature',  xr=[0.6,1.4]
	oplot,j[i_bad]-k[i_bad], abs_k[i_bad], psym=1, color=250
	oplot, j[i_fit]-k[i_fit], jk_ms, psym=8, symsize=2, color=250

	print_struct, jason[i_bad]
	return, jason[i_ok]
	
END
