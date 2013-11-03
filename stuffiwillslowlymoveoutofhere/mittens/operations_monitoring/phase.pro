PRO find_phase, star, period_range, pause
	p = findgen(100)/100.*(period_range[1] - period_range[0]) + period_range[0]
	for i =0, n_elements(p)-1 do begin
		plot, star.hjd mod p[i], star.flux, psym=1, /yno, title=p[i]
		wait, pause
	endfor
END

PRO phase, star, period, eps
	set_plot, 'ps'
	device, filename=eps
	plot, (star.hjd mod period)/period, star.flux, psym=1, /yno, title=period, yrange=[max(star.flux), min(star.flux)], xtitle='Phase', ytitle='Magnitude'
	device, /close
	set_plot, 'x'
END