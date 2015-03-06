FUNCTION tfa_test, filename, pause, eps=eps
	trimmed = trim_lc(filename, n_sigma=3, n_trim=.2, star=-42)

	!p.multi=[0,2,2,0,1]
	

	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename='tfa/'+trimmed.object+'_east_tfa.eps', /inches, xsize=7.5, ysize=10, /color, /encapsulated
	endif	

	if n_tags(trimmed.east[0]) gt 0 then begin; and n_tags(trimmed.west[0]) eq 0 then begin
		target = trimmed.east[0]
		comparisons = trimmed.east[1:*]
	endif
	
;	if n_tags(trimmed.east[0]) gt 0 and n_tags(trimmed.west[0]) gt 0 then begin
;		target = recombine_meridians(trimmed.east[0], trimmed.west[0])
;		comparisons = replicate(target, n_elements(trimmed.east)-1)
;		for i=0, n_elements(comparisons)-1 do comparisons[i] = recombine_meridians(trimmed.east[i+1], trimmed.west[i+1])
;	endif
;	if n_tags(trimmed.east[0]) gt 0 and n_tags(trimmed.west[0]) eq 0 then begin
;		target = trimmed.east[0]
;		comparisons = trimmed.east[1:*]
;	endif
;	if n_tags(trimmed.east[0]) eq 0 and n_tags(trimmed.west[0]) gt 0 then begin
;		target = trimmed.west[0]
;		comparisons = trimmed.west[1:*]
;	endif

	if keyword_set(target) then if n_elements(target.flux) gt 100 then begin
		q = tfa(target, comparisons, trimmed.object)
		wait, pause
	end

	
;	if keyword_set(eps) then begin
;;		set_plot, 'ps'
;		device, filename='tfa/'+trimmed.object+'_east_tfa.eps', /inches, xsize=7.5, ysize=10, /color, /encapsulated
;	endif	
;;	
;	if n_tags(trimmed.east[0]) gt 0 then if n_elements(trimmed.east[0].flux) gt 100 then begin
;		q = tfa(trimmed.east[0], trimmed.east[1:*], trimmed.object)
;		if keyword_set(east_scatter_before) then  east_scatter_before = [east_scatter_before,q.scatter_before] else east_scatter_before=q.scatter_before
;		if keyword_set(east_scatter_after) then east_scatter_after = [east_scatter_after,q.scatter_after] else east_scatter_before=q.scatter_after
;	endif
;	if keyword_set(eps) then begin
;		device, /close
;		set_plot, 'x'
;	endif
;	
;	if keyword_set(eps) then begin
;		set_plot, 'ps'
;		device, filename='tfa/'+trimmed.object+'_west_tfa.eps', /inches, xsize=7.5, ysize=10, /color, /encapsulated
;	endif	
;	if n_tags(trimmed.west[0]) gt 0 then if n_elements(trimmed.west[0].flux) gt 100 then begin
;		q = tfa(trimmed.west[0], trimmed.west[1:*], trimmed.object)
;		if keyword_set(west_scatter_before) then west_scatter_before = [west_scatter_before,q.scatter_before] else west_scatter_before=q.scatter_before
;		if keyword_set(west_scatter_after) then  west_scatter_after = [west_scatter_after,q.scatter_after] else west_scatter_before=q.scatter_after
;	endif
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
	endif
	if not keyword_set(q) then q = -1
	return, q
END

PRO plot_coefs, eps=eps
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename='coef_scatters.eps', /encapsulated, /inches, xsize=7.5, ysize=10, /color
	endif
	spawn, 'ls tfa/*_coefs.idl', result
	for i=0, n_elements(result)-1 do begin
		restore, result[i]
		if keyword_set(scatter_before) then scatter_before = [scatter_before, q.scatter_before] else scatter_before = q.scatter_before
		if keyword_set(scatter_after) then scatter_after = [scatter_after, q.scatter_after] else scatter_after = q.scatter_after
		if keyword_set(coef) then coef = [coef, q.coef] else coef = q.coef
		if keyword_set(j_m) then j_m = [j_m, q.comparisons.j_m] else j_m = q.comparisons.j_m
		if keyword_set(h_m) then h_m = [h_m, q.comparisons.h_m] else h_m = q.comparisons.h_m
		if keyword_set(k_m) then k_m = [k_m, q.comparisons.k_m] else k_m = q.comparisons.k_m
		if keyword_set(x) then x = [x, q.comparisons.x - q.target.x] else x = q.comparisons.x - q.target.x
		if keyword_set(y) then y = [y, q.comparisons.y - q.target.y] else y = q.comparisons.y - q.target.y
	endfor
	!p.multi=[0,2,3, 0, 0]
	help
	x_axis = findgen(10) - 5.0
	lf = linfit(j_m-h_m, coef)
	plot, j_m-h_m, coef, xtitle='J-H', ytitle='Coefficient', psym=3, symsize=0.5, yrange=[-1.5, 1.5], title=correlate(j_m-h_m, coef)
	oplot, x_axis, lf[0] + lf[1]*x_axis, linestyle=2
	print, lf
	lf = linfit(h_m-k_m, coef)
	plot, h_m-k_m, coef, xtitle = 'H-K', ytitle='Coefficient', psym=3, symsize=0.5, yrange=[-1.5, 1.5], title=correlate(h_m-k_m, coef)
	oplot, x_axis, lf[0] + lf[1]*x_axis, linestyle=2
	print, lf
	plot, x, coef, xtitle='x', ytitle='Coefficient', psym=3, symsize=0.5, yrange=[-1.5, 1.5]
	plot, y, coef, xtitle='y', ytitle='Coefficient', psym=3, symsize=0.5, yrange=[-1.5, 1.5]
	plot, scatter_before, scatter_after, psym=4, symsize=0.5, xrange=[0,.03], xtitle=textoidl('\sigma_{original}'), ytitle=textoidl('\sigma_{TFA}')
	oplot, findgen(100)/1000, findgen(100)/1000, linestyle=1
	plot, scatter_before, (scatter_after - scatter_before)/scatter_before, psym=4, symsize=0.5, xrange=[0,.03], xtitle=textoidl('\sigma_{original}'), ytitle=textoidl('(\sigma_{TFA} - \sigma_{original})/\sigma_{original}')
	oplot, [0,1], [0,0], linestyle=1
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
	endif
END

PRO make_tfa, tel, pause=pause, eps=eps

	if NOT keyword_Set(pause) then pause =0
	tel_string = 'tel0' + string(tel, format='(I1)')
	dir = '/pool/barney0/mearth/reduced/' + tel_string + '/master/'
	command = 'ls -R ' + dir + 'lspm*_lc.fits'
	spawn, command, result
	for i=0, n_elements(result)-1 do begin
		q = tfa_test(result[i], pause, eps=eps)
		if n_tags(q) gt 0 then begin
			save, q, filename='tfa/'+q.object+'_coefs.idl'
		endif
	;	print, result[i]
	endfor
	;return, {scatter_before:scatter_before, scatter_after:scatter_after, coef:coef, comparisons:comparisons}
END

FUNCTION nearby_comparisons, target, possible_comparisons, n_comp
	m = n_elements(possible_comparisons)
	print, " the target's median brightness is", target.medflux
	print, '     @ of ', m, ' possible comparison stars'
	radial_offset = sqrt((possible_comparisons.x - target.x)^2 + (possible_comparisons.y - target.y)^2)
	bright_mag_limit = target.medflux-2
	faint_mag_limit = target.medflux + 1.0
	i_okay_bright = where(possible_comparisons.medflux gt bright_mag_limit and possible_comparisons.medflux lt faint_mag_limit and median(finite(possible_comparisons.flux), dimension=1) gt 0, n_okay_bright)
	print, '     @   there are ', n_okay_bright, ' decent stars between ', bright_mag_limit, ' and ', faint_mag_limit
	;print, '     @   of which ', min([n_comp, n_okay_bright]), ' random stars were chosen'
	if min([n_comp, n_okay_bright]) gt 0 then begin
;		bad = 1
;		while (bad ne 0) do begin
;			bad =0
;			random_indices = uint(randomu(seed,min([n_comp, n_okay_bright]))*n_okay_bright)
;			for i=0, min([n_comp, n_okay_bright])-1 do begin
;				overlap = where(random_indices eq random_indices[i], n_overlap)
;				if n_overlap gt 1 then bad = 1
;			endfor
;		endwhile
;		print, random_indices
		return, possible_comparisons[i_okay_bright]
	endif else return, -1
END

FUNCTION tfa, target, possible_comparisons, object
	!p.charsize=1.0
	!p.symsize=0.2
	!p.charthick=1.0
	loadct, 39

	comparisons = nearby_comparisons(target, possible_comparisons, 5)
	is_okay = fltarr(n_elements(comparisons))
;	for i=0, n_elements(comparisons)-1 do is_okay[i] = total(finite(comparisons[i].flux)) gt n_elements(target.flux)/2.0	
;	comparisons = comparisons[where(is_okay)]
	targ_flux = target.flux - median(target.flux)
	N = n_elements(targ_flux)
	M = n_struct(comparisons)
	A = dblarr(N,M)
	for i=0, M-1 do A[*,i] = sigma_clip_zero(comparisons[i].flux)/target.fluxerr
	b = targ_flux/target.fluxerr
	alpha = transpose(A)#A
	beta = transpose(A)#b
	c = invert(alpha, /double)
	coef = c#beta
	filter = A#coef
	tf_targ_flux = (b - filter)*target.fluxerr
	tf_target = target
	tf_target.flux = median(target.flux)+tf_targ_flux
	
	comparisons = comparisons[reverse(sort(abs(coef)))]
	coef = coef[reverse(sort(abs(coef)))]
	print, '    @ the coefs in the fit are:'
	print, coef

	if m gt 5 then return, tfa(target, comparisons[0:4], object) else begin
	
		scatter_before = sqrt(total((targ_flux-mean(targ_flux))^2)/n)
		scatter_after = sqrt(total((tf_targ_flux-mean(tf_targ_flux))^2)/(n-m))


		n_rows = min([M+2, 15])
		n_cols = (M+1)/n_rows+1
		
		multiplot, /init, [0,n_cols,n_rows, 0, 0]	
		yrange = [max(targ_flux), min(targ_flux)]
		multiplot & plot, targ_flux, psym=4, symsize=0.3, ytitle=object, yrange=yrange, title='(before) '+string(stddev(targ_flux), format='(F6.4)')
	
	
		for i=0, M-1 do begin
			multiplot & plot, comparisons[i].flux - median(comparisons[i].flux), psym=1, yrange=yrange, symsize=0.3
			xyouts, 0.01*n_elements(comparisons[i].flux), 0.7*min(targ_flux), coef[i], color=250
		endfor

		multiplot & plot, tf_targ_flux, psym=4, symsize=0.3, yrange=yrange, xtitle='(after) '+string(stddev(tf_targ_flux),format='(F6.4)')+ ' ('+ string(scatter_after, format='(F6.4)') +')'
	
		multiplot, /default	
		return, {target:tf_target, scatter_before:scatter_before, scatter_after:scatter_after, n:n, m:m, comparisons:comparisons, coef:coef, object:object}
	endelse	
END