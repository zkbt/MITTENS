FUNCTION make_messylc, tel, n_sigma, n_trim, pause=pause, eps=eps, show_plot=show_plot
	if NOT keyword_Set(pause) then pause =0
	tel_string = 'tel0' + string(tel, format='(I1)')
	dir = '/pool/barney0/mearth/reduced/' + tel_string + '/master/'
	command = 'ls -R ' + dir + '/*_lc.fits'
	spawn, command, result
	bad_obs_path = 'nights/t0'+string(tel, format='(I1)')+'/'
	if keyword_set(eps) then eps_path = 'nights/t0'+string(tel, format='(I1)')+'/'
	rms_array = fltarr(n_elements(result), 4)
	for i=0, n_elements(result)-1 do begin
		lc = trim_lc(result[i], pause=pause, n_sigma=n_sigma, n_trim=n_trim, eps_path=eps_path, show_plot=show_plot, bad_obs_path=bad_obs_path)
		rms_array[i,*] = lc.rms
	endfor
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename=tel_string+'scatters.eps', /color, /encapsulated, /inches, xsize=7.5, ysize=5
	endif
	lines = [0,0,2,2]
	colors = [70,250,70,250]
	thicks = [2,2,4,4]
	bin= 2.5
	!p.charsize=1
	!p.symsize=1
	top =0
	med = fltarr(4)
	for i=0, 3 do begin
		plothist, rms_array[where(rms_array[*,i] gt 0),i]*1000, bin=bin, xaxis, yaxis, /noplot
		top  = max([top, yaxis])
		med[i] = median(rms_array[where(rms_array[*,i] gt 0),i]*1000,dimension=1)
	endfor
	plothist, rms_array[where(rms_array[*,0] gt 0),0]*1000, bin=bin, thick=thicks[0], xrange=[0,50], yrange=[0,top], linestyle=lines[0], color=colors[0], xtitle='(trad. defined) standard deviation of target flux (millimag)', ytitle='number of target stars', title=tel_string+' | trim = reject with 1/'+ string(1/n_trim, format='(I1)') + ' - ' + string(n_sigma, format='(I1)') + textoidl('\sigma') + ' outliers'
	for i=1,3 do plothist, /overplot, rms_array[where(rms_array[*,i] gt 0),i]*1000, thick=thicks[i], linestyle=lines[i], color=colors[i], bin=bin
	legend, linestyle=lines, color=colors, ['left before trim', 'right before trim', 'left after trim', 'right after trim']+ string(med), /right, /top
	if keyword_set(ps) then begin
		device, /close
		set_plot, 'x'
	endif
	return, rms_array
END