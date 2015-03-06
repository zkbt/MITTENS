PRO plot_scopes, range, filename=filename, hours=hours, seeing=seeing, ellipticity=ellipticity, stdcrms=stdcrms, max_tel=max_tel

	dt_max = 15./60./24.
	max_wind = 100
	
	if keyword_set(filename) then begin
		set_plot, 'ps'
		device, filename='plots/'+filename, /encapsulated, /color, xsize=10, ysize=7.5, /inches
		print, filename
	endif
	
	!p.multi=[0,1,8]
	zp = 0
	zerr = 0
	z_tel = 0
	for tel=1,max_tel do begin 
		plot_days, range, tel, dt_max,max_wind, zero_point, zero_error, hours=hours, seeing=seeing, ellipticity=ellipticity, stdcrms=stdcrms
;		zp = [zp, zero_point]
;		zerr = [zerr, zero_error]
;		z_tel = [z_tel, tel+fltarr(n_elements(zero_point))]
		save, hours, filename=string(tel, format='(I1)')+'.idl'
	endfor
	
	if keyword_set(filename) then begin
		device, /close
		set_plot, 'x'
	endif
	
;	if keyword_set(filename) then begin
;		set_plot, 'ps'
;		device, filename="hists_"+filename, /encapsulated, /color, xsize=7.5, ysize=10, /inches
;	endif
;	
;	for tel=1,8 do begin
;		i = where(z_tel eq tel)
;		plothist, zp[i], bin=0.01, xrange=[20,22], xtitle='zero point (mag.)', ytitle='number'
;	endfor
;	
;		if keyword_set(filename) then begin
;		device, /close
;		set_plot, 'x'
;	endif
	
	plot_summary, filename=filename, max_tel=max_tel
	
END
