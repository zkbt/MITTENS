FUNCTION lomb_scargle, t, h, h_err, res=res, making_fake=making_fake

	N = n_elements(h)
        t -= t[0]
	if (N NE n_elements(t)) then print, "Sorry, the data arrays don't match in size."
	h_mean = total(h/h_err^2)/total(1.0d/h_err^2)
      ;  print, 'means:', h_mean, mean(h)
	var = total((h-h_mean)^2/h_err^2)/total(1.0/h_err^2)*N/(N-1.0)
;        print, 'variances:', median(h_err), var
	if (NOT keyword_set(res)) then res = N/10
	
	w_min = 2.0*!pi/100.0;(max(t) - min(t))/2
	w_max = 2.0*!pi/2.0;(1.0/24.0)
	w_bin = (w_max - w_min)/res
	w = findgen(res)*w_bin + w_min
	
	P = fltarr(res)
	
	for i=0l, res-1 do begin
		tau = 1.0/2.0/w[i]*atan(total(sin(2.0*w[i]*t)/h_err^2)/total(cos(2.0*w[i]*t)/h_err^2))
	;	P[i] = 1.0/2.0/var*(total((h-h_mean)*cos(w[i]*(t-tau)))^2/total((cos(w[i]*(t-tau)))^2) + total((h-h_mean)*sin(w[i]*(t-tau)))^2/total((sin(w[i]*(t-tau)))^2))
		P[i] = 1.0d/2.0*(total((h-h_mean)/h_err^2*cos(w[i]*(t-tau)))^2/total((cos(w[i]*(t-tau)))^2/h_err^2) + total((h-h_mean)/h_err^2*sin(w[i]*(t-tau)))^2/total((sin(w[i]*(t-tau)))^2/h_err^2));/total(1.0/h_err^2);/total(1.0/h_err^2)

	endfor
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
	
	plot, (w/2./!pi), P, /xstyle, xtitle=textoidl('Frequency (inverse days)'), ytitle=textoidl('P_{N}')
;	oplot, 1./(fake.w/2./!pi), fake.P, color=200
	p_fake = [0.1, 0.01, 0.001, 0.0001, 0.00001]
;	for i=0, n_elements(p_fake)-1 do begin
;		oplot, [.1,10000], [-alog(p_fake[i]/N), -alog(p_fake[i]/N)], linestyle=2
;		xyouts, 0.07, -alog(p_fake[i]/N), string(p_fake[i], format='(F7.5)'), charsize=0.4
;	endfor
	return, {w:w, P:P}
END
