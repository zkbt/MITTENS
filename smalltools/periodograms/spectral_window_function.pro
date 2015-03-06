PRO spectral_window_function, lc,res=res, period_range=period_range, v, swf, yrange=yrange, top=top, bottom=bottom, left=left, right=right

	;+
	;NAME:
	;       SPECTRAL_WINDOW_FUNCTION
	;
	; PURPOSE:
	;	Calculate the spectral window function of a time-series.
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

	if n_tags(lc) eq 0 then t = lc else t = lc.hjd - lc[0].hjd
	clip_limit = 5.0
	N = n_elements(t)
	ok = indgen(N)
	t = t[sort(t)]


	if (NOT keyword_set(res)) then res = N*10

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

	swf = total(exp(complex(0, 1)*w#t),2)
	swf /= N

		xrange=[0, max(v)]

	if keyword_set(left) then begin
		yrange=[0, max(abs(swf)^2)*1.1]
		ytitle='Power'
	endif else begin
		ytitle=''
	endelse	
	if keyword_set(right) then begin
		
	endif
	if keyword_set(top) then begin
		xtitle=''
	endif
	if keyword_set(bottom) then begin
		xtitle='Frequency (1/day)'
	endif else begin
		xtitle=''
	endelse

	plot, v, abs(swf)^2, xstyle=1, ystyle=1, xtitle=xtitle, ytitle=ytitle, yrange=yrange, xrange=xrange
;	oplot_dials, v, swf




END