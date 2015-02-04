PRO periodogram, input_lc, res=res, period_range=period_range, decorrelate=decorrelate, yrange=yrange, top=top, bottom=bottom, left=left, right=right, middle=middle, bestfit_correction=bestfit_correction, null_correction=null_correction, model=model, filename=filename, ok=ok, xrange=xrange, label=label, input_period=input_period, no_peak=no_peak, v=v, chi_sq=chi_sq, pfa=pfa,plot=plot, sin_params=sin_params

	;+
	;NAME:
	;       PERIODOGRAM
	;
	; PURPOSE:
	;	Calculate the maximum likelihood (chi^2 sense) periodogram of a light curve.
	;
	; CALLING SEQUENCE:
	;       periodogram, lc
	;
	; INPUT:
	;       lc = light curve structure containing at least .hjd, .flux, .fluxerr
	;
	; OUTPUT ARGUMENTS:
	;       
	; OPTIONAL INPUT KEYWORDS:
	;       
	; REVISION HISTORY:
	;
	;-

	!y.margin=[5,5]
	if not keyword_set(label) then label=''
	if not keyword_set(period_range) then period_range=[min(input_lc[1:*].hjd - input_lc.hjd), max(input_lc.hjd) - min(input_lc.hjd)]
	lc = input_lc[sort(input_lc.hjd)]
	if keyword_set(input_hjd0) then t = lc.hjd - input_hjd0 else t = lc.hjd - lc[0].hjd
	h = lc.flux
	h_err = lc.fluxerr
	clip_limit = 5.0
	if keyword_set(ok) then N=n_elements(ok) else ok = where(finite(h/h_err), N, complement=notok); and abs(h) lt 5.0*1.48*mad(h), N, complement=notok)

	upper_limit = 1.0/max(t)
;	h_mean = total(h[ok]/h_err[ok]^2)/total(1.0d/h_err[ok]^2)
;	var = total((h[ok]-h_mean)^2/h_err[ok]^2)/total(1.0/h_err[ok]^2)*N/(N-1.0)

	if (NOT keyword_set(res)) then res = 10000;N*100

	if keyword_set(period_range) then begin
		w_max = 2*!pi/min(period_range)
		w_min = 2*!pi/max(period_range)
	endif else begin
		w_min = 2.0*!pi/(max(t) - min(t))
		w_max = 2.0*!pi/(abs(min(t[1:*] - t))/2.0 > 0.1)
	endelse
	w_bin = (w_max - w_min)/res
	w = findgen(res)*w_bin + w_min
	v = w/2/!pi
	period = 1.0/v

	chi_sq = fltarr(res) + 1e10
        P = fltarr(res)
	M = 3
	if keyword_set(decorrelate) then begin
		for j=0, n_elements(decorrelate)-1 do begin
			tags = tag_names(lc)
			k = where(tags eq decorrelate[j], n_tag_match)
			if n_tag_match eq 1 then begin
				if stddev(lc.(k)) gt 0 then begin
					M += 1 
					if n_elements(keepers) eq 0 then keepers = j else keepers = [keepers, j]
				endif else print, "!#%&!)* couldn't find the tag ", decorrelate[j], " to decorrelate off of!"
			endif
		endfor
		if n_elements(keepers) gt 0 then actually_decorrelate = decorrelate[keepers]

	endif
        A = fltarr(N, M)
        b = h[ok]/h_err[ok]
	if n_elements(actually_decorrelate) gt 0 then begin
		for j=0, n_elements(actually_decorrelate)-1 do begin
			tags = tag_names(lc)
			k = where(tags eq actually_decorrelate[j], n_tag_match)
			if n_tag_match eq 1 then A[*,j] = (lc[ok].(k) - mean(lc[ok].(k)))/h_err[ok]
		endfor
	endif
	A[*,M-3] = 1.0/h_err[ok]
	for i=0l, res-1 do begin
		A[*,M-2] = sin(w[i]*t[ok])/h_err[ok]
		A[*,M-1] = cos(w[i]*t[ok])/h_err[ok]
		alpha = transpose(A)#A
		beta = transpose(A)#b
		c = invert(alpha, /double)
		coef = c#beta
		chi_sq[i] = total((b-A#coef)^2)

	endfor

	A_null = A[*, 0:M-3]
	alpha_null = transpose(A_null)#A_null
	beta_null = transpose(A_null)#b
	c_null = invert(alpha_null, /double)
	coef_null = c_null#beta_null
	chi_sq_null = total((b - A_null#coef_null)^2)
	null_correction = fltarr(n_elements(h)) + 0.0/0.0
	null_correction[ok] = (A_null#coef_null)*h_err[ok]

	p =chi_sq;chi_sq_null - chi_sq;(N-M)/2.0*(chi_sq_null - chi_sq)/min(chi_sq)
	Nyquist_period = 2*(max(t) - min(t))/N
	Nyquist_freq = 2*!pi/nyquist_period

	i_peaks = peaks(chi_sq_null - chi_sq)
	i_peaks = i_peaks[where(v[i_peaks] gt upper_limit)]
	i_peaks = i_peaks[reverse(sort(chi_sq_null - chi_sq[i_peaks]))]
	A_original = A
	n_peaks = 1
	for i=0, n_peaks-1 do begin
		if keyword_set(input_period) then this_w = 2.0*!pi/input_period else this_w = w[i_peaks[i]]
		A = A_original
		A[*,M-2] = sin(this_w*t[ok])/h_err[ok]
		A[*,M-1] = cos(this_w*t[ok])/h_err[ok]
		alpha = transpose(A)#A
		beta = transpose(A)#b
		c = invert(alpha, /double)
		coef = c#beta
		;print, coef
		this_model = fltarr(n_elements(h)) + 0.0/0.0
		this_bestfit_correction = this_model
		this_model[ok] = A#coef*h_err[ok]
		this_bestfit_correction[ok] = this_model[ok] - A[*,M-2]*coef[M-2]*h_err[ok] - A[*,M-1]*coef[M-1]*h_err[ok]
		if n_elements(model) eq 0 then model = this_model else model = [[model],[this_model]]
		if n_elements(bestfit_correction) eq 0 then bestfit_correction = this_bestfit_correction else bestfit_correction = [[bestfit_correction],[this_bestfit_correction]]	
		phase =	atan(coef[M-1], coef[M-2]) ;+ !pi*(coef[M-2] lt 0)
		t0 = lc[0].hjd - phase/this_w
		sin_params = {period:2.0*!pi/this_w, a:sqrt(coef[M-2]^2 + coef[M-1]^2), hjd0:t0, constant:coef[M-3]}
		print, label, 2.0*!pi/this_w, sqrt(coef[M-2]^2 + coef[M-1]^2), string(t0, format='(D15.7)')
		print, 'amplitude error:', sqrt(c[M-2, M-2] + c[M-1,M-1]);, string(t0, format='(D15.7)')
		print, 'to error:', sqrt(c[m-1, m-1]*coef[M-2]^2 + c[m-2, m-2]*coef[M-1]^2)/this_w/(coef[m-1]^2 + coef[M-2]^2)
;		plot, lc.hjd, model - bestfit_correction, psym=1
;		oplot, lc.hjd, sqrt(coef[M-2]^2 + coef[M-1]^2)*sin(this_w*(lc.hjd - t0))
;		wait, 4
	endfor
;	m = n_elements(t)*(w_max-w_min)/nyquist_freq
;	N_fakes = 100
;	P_fake = 1.0/N_fakes
;	fake = fake_lomb(t, N_fakes)
;	print, z_rough
	
;	plot, w/2./!pi, P, /xstyle, xtitle=textoidl('Frequency (hours^{-1})'), ytitle=textoidl('P_{N}'), thick=2
;	oplot, fake.w/2./!pi/1., fake.P, color=220
;	oplot, [0,1000], [z_rough, z_rough], color=240
;	oplot, [Nyquist_even, Nyquist_even]/2./!pi/1., [0,1000], linestyle=1
;	xyouts, max( w/2./!pi/1.)*0.9, max(P)*0.9, strcompress(string(P_fake*100.0, format='(g8.4)'))+'%', color=10
		xrange=[0, 1.0/min(period_range)]

	if keyword_set(left) then begin
		yrange=[0, max(chi_sq_null - chi_sq)*1.25];[0, max(P)*1.1]
	endif
	if keyword_set(left) and keyword_set(bottom) then ytitle=goodtex('                                                       \Delta\chi^2 = \chi^2_{null} - \chi^2_{sine}') else ytitle=''
	if keyword_set(right) then begin
		
	endif
	if keyword_set(top) then begin
		xtitle=''
	endif
	if keyword_set(bottom) then begin
		xtitle='Frequency (1/day)'
	endif
	xtickv = findgen(6)/5*max(v)
	y = chi_sq_null - chi_sq
	if keyword_set(pfa) then begin
		restore, 'LC'+repstr(strmid(label, 0, 1000), ' ', '_')+ 'chi_to_pfa.idl'
		y = interpol(cdf, x, chi_sq_null - chi_sq);cdf[value_locate(x, chi_sq_null - chi_sq)]
		pfa_to_plot = [0.5,0.1, 0.01, 0.001]
		chi_to_plot = interpol(x, cdf, pfa_to_plot)
		ytickv = chi_to_plot
		ytickn = strcompress(string(format='(F5.3)', pfa_to_plot), /remo)
	endif
;yrange = [1.0, 0.0001]
;	!x.margin = [10,10]
	plot, v, chi_sq_null - chi_sq, xtitle=xtitle, ytitle=ytitle, yrange=yrange, ystyle=5, xrange=xrange, xtick_get=xtickv, xstyle=3, thick=2
	if keyword_set(left) then begin
		axis, yaxis=0, ytitle=ytitle
	;	if keyword_set(pfa) then axis, yaxis=1, ytickv=ytickv, ytickn=replicate(' ', n_elements(pfa_to_plot)), yticks=n_elements(pfa_to_plot)-1 else axis, yaxis=1
	endif
	if keyword_set(right) then begin
		axis, yaxis=0
		if keyword_set(pfa) then axis, yaxis=1, ytickv=ytickv, ytickn=ytickn, yticks=n_elements(pfa_to_plot)-1, ytitle='Prob. of False Alarm' else axis, yaxis=1
	endif
	if keyword_set(left) then xyouts, mean(xrange), yrange[1], '!C'+strcompress(/remove_all, N-M)+ ' degrees of freedom', charsize=0.8, alignment=0.5, charthick=2
	polyfill, [-100,upper_limit, upper_limit, -100], [1e5,1e5,-1e5,-1e5], noclip=0, spacing=0.1, orientation=45

	lines=[0,2,1]

	if keyword_set(right) and not keyword_set(no_peak) then begin
		for i=0, n_peaks-1 do if v[i_peaks[i]] gt min(v) then xyouts, v[i_peaks[i]], chi_sq_null - chi_sq[i_peaks[i]]*.95, strcompress(/remove_all, string(1.0/v[i_peaks[i]], format='(F6.1)')), charsize=0.8, color=250, alignment=0.5, charthick=3*(n_peaks-i)
		for i=0, n_peaks-1 do oplot, [1,1]*v[i_peaks[i]], [yrange[0]*1.1, (chi_sq_null - chi_sq[i_peaks[i]])*0.85], linestyle=lines[i], thick=3*(n_peaks-i), color=250
	endif
	if keyword_set(right) then xyouts, mean(xrange), yrange[1], '!C'+label, alignment=0.5, charsize=1, charthick=5

;	n_ticks = 5
;	periods = 1.0/(-findgen(n_ticks)*(max(v) - min(v))/n_ticks + max(v))
;	xtickv = 1.0/periods
;	periods = min(1.0/v) + min(1.0/v)*findgen(n_ticks)/n_ticks*(1.0/xtickv[0]/2.0 - min(1.0/v))
;	periods = min(1.0/v)*[findgen(n_ticks)*(max(1.0/v) - min(1.0/v))
;	xtickv = 1.0/periods
;	xtickv = 1.0/periods
	xtickv = [xtickv[sort(xtickv)]]
;	print, xtickv
;	print, periods
	xtickn=strcompress(string(1.0/xtickv, format='(F6.2)'), /remove_all)
	for i=0, n_elements(xtickn)-1 do if xtickn[i] eq '******' then xtickn[i] = ' '
	if keyword_set(top) then axis, xaxis=1, xtitle='Period (day)', xtickv=xtickv, xtickn=xtickn, xticks=10, ticklen=-0.02
	if keyword_set(bottom) then axis, xaxis=0, ticklen=-0.02, xrange=xrange, xstyle=3, xtickn=replicate(' ',60)
	top_v = v[i_peaks[0:n_peaks-1]]
	if keyword_set(filename) then save, bestfit_correction, sin_params, null_correction, model, ok, notok, n_peaks, top_v,  filename=filename

	if keyword_set(plot) then begin
		window, 5
		@psym_circle
		ploterror, (t - sin_params.t0) mod sin_params.period, h, h_err, psym=8

	endif
END