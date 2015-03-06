FUNCTION sin_fit, times, h, h_err, res=res, making_fake=making_fake, period_range=period_range, no_plot=no_plot, lc=lc, ok=ok, title=title

	if keyword_set(lc) then begin
		times = lc.hjd
		h = lc.flux
		h_err = lc.fluxerr
	endif
	clip_limit = 5.0
	if keyword_set(ok) then N=n_elements(ok) else ok = where(finite(h), N)

	t = times - times[0]
	if (N NE n_elements(t[ok])) then print, "Sorry, the data arrays don't match in size."
	h_mean = total(h[ok]/h_err[ok]^2)/total(1.0d/h_err[ok]^2)
;        print, 'means:', h_mean, mean(h)
	var = total((h[ok]-h_mean)^2/h_err[ok]^2)/total(1.0/h_err[ok]^2)*N/(N-1.0)
 ;       print, 'variances:', median(h_err)^2, var
	if (NOT keyword_set(res)) then res = N;*5
	
	if keyword_set(period_range) then begin
		w_max = 2*!pi/min(period_range)
		w_min = 2*!pi/max(period_range)
	endif else begin
		w_min = 2.0*!pi/(max(t) - min(t))/2
		w_max = 2.0*!pi/0.1
	endelse
	w_bin = (w_max - w_min)/res/2
	w = findgen(res)*w_bin + w_min
	

	chi_sq = fltarr(res)
	chi_sq_mean = fltarr(res)
        P = fltarr(res)
        M = 3
        A = fltarr(N, M)
        b = h[ok]/h_err[ok]

	for i=0l, res-1 do begin
            A[*,0] = sin(w[i]*t)/h_err[ok]
            A[*,1] = cos(w[i]*t)/h_err[ok]
	    A[*,2] = 1.0/h_err[ok]
            alpha = transpose(A)#A
            beta = transpose(A)#b
            c = invert(alpha, /double)
            coef = c#beta
            chi_sq[i] = total((b-A#coef)^2)
	endfor
		chi_sq_mean = total((h[ok] - h_mean)^2/h_err[ok]^2)

	p = (N-3)/2.0*(chi_sq_mean - chi_sq)/min(chi_sq)
	Nyquist_period = 2*(max(t) - min(t))/N
	Nyquist_freq = 2*!pi/nyquist_period

	if (keyword_set(making_fake)) then begin
		return, {w:w, P:P}
	endif
	
	m = n_elements(t)*(w_max-w_min)/nyquist_freq
;	N_fakes = 100
;	P_fake = 1.0/N_fakes
;	fake = fake_lomb(t, N_fakes)
;	print, z_rough
	
;	plot, w/2./!pi, P, /xstyle, xtitle=textoidl('Frequency (hours^{-1})'), ytitle=textoidl('P_{N}'), thick=2
;	oplot, fake.w/2./!pi/1., fake.P, color=220
;	oplot, [0,1000], [z_rough, z_rough], color=240
;	oplot, [Nyquist_even, Nyquist_even]/2./!pi/1., [0,1000], linestyle=1
;	xyouts, max( w/2./!pi/1.)*0.9, max(P)*0.9, strcompress(string(P_fake*100.0, format='(g8.4)'))+'%', color=10
	
	if not keyword_set(no_plot) and total(finite(P)) gt 1 then begin
		plot, 1./(w/2./!pi), P, /xstyle,/xlog, xtitle=textoidl('Period (days)'), ytitle=textoidl('P_{N}'), title=title
	;	plot, 1./(w/2./!pi), chi_sq_mean - chi_sq, /xstyle,/xlog, xtitle=textoidl('Period (days)'), ytitle=goodtex('\Delta \chi^2')	
;	        plot, 1./(w/2./!pi), chi_sq, /xstyle,/xlog, xtitle=textoidl('Period (days)'), ytitle=textoidl('\chi^{2}'), /yno
	endif
;	oplot, 1./(fake.w/2./!pi), fake.P, color=200
	p_fake = [0.1, 0.01, 0.001, 0.0001, 0.00001]
;	for i=0, n_elements(p_fake)-1 do begin
;		oplot, [.1,10000], [-alog(p_fake[i]/N), -alog(p_fake[i]/N)], linestyle=2
;		xyouts, 0.07, -alog(p_fake[i]/N), string(p_fake[i], format='(F7.5)'), charsize=0.4
;	endfor
;	plot, w, p
	i = where(chi_sq eq min(chi_sq, /nan))
	best_period = 1./(w[i]/2/!pi)
;	print, best_period

	return, {w:w, P:P, chi_sq:chi_sq, best_period:best_period}
END
