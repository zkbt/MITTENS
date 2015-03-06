PRO estimate_overheads
		erase
	set_plot, 'ps'
	device, filename='super_estimate_overheads.eps', /encap, xsize=10, ysize=2.5, /inches
	!p.charsize=0.4
	!y.style = 4
	smultiplot, /init, [8,3], ygap=0.005, /rowm, xgap=0.005
	for t=1, 8 do begin
		e = load_exposures(ye=11, te=t)
		e = e[sort(e.mjd)]
		e = e[uniq(long((e.mjd - min(e.mjd))*10000000L))]
		i_newpointings = [-1, where(e[1:*].ls ne e[0:*].ls, n_newpointings)]
		s = create_struct('LS', 0, 'YE', 0, 'TE', 0, 'MJD', 0.0d, 'EXPTIME', 0.0,  'NEXP', 0, 'TIMEREADING', 0.0, 'TIMESLEWING', 0.0, 'AST', 0B)
		pointings = replicate(s, n_newpointings)
		for i=0, n_newpointings-2 do begin
			n_thispointing = i_newpointings[i+1] - i_newpointings[i]
			i_thispointing = lindgen(n_thispointing) + i_newpointings[i]+1
	
	;		print, e[i_thispointing].ls
			copy_struct, e[i_newpointings[i]+1], s
			s.exptime = total(e[i_thispointing].exptime)
			s.nexp = n_thispointing
			s.timereading = 24.*60.*60.*(e[i_newpointings[i]+n_thispointing].mjd - e[i_newpointings[i]+1].mjd) - e[i_newpointings[i]+1].exptime*(s.nexp-1)
			s.timeslewing = 24.*60.*60.*(e[i_newpointings[i+1]+1].mjd  - e[i_newpointings[i+1]].mjd) -  (e[i_newpointings[i+1]+1].exptime  + e[i_newpointings[i+1]].exptime)/2.0
			pointings[i] = s
			
		endfor
		i = where(pointings.nexp gt 1)
		bin = 2
		xr = [0,150]
		smultiplot
		if t eq 1 then !y.title = 'Time Reading' else !y.title=''
		plothist, pointings[i].timereading/pointings[i].nexp, /nan, xr=xr, bin=bin, title='tel' + string(form='(I02)', t);, /ylog
		al_legend, box=0,/right, string(median(pointings[i].timereading/pointings[i].nexp), form='(F4.1)') + ' sec.'+ '!C' + string(mean(pointings[i].timereading/pointings[i].nexp), form='(F4.1)') + ' sec.'

			
		smultiplot
		if t eq 1 then !y.title = 'Time Exposing' else !y.title=''
		plothist, pointings.exptime, /nan, xr=xr, bin=bin;, /ylog
		plothist, pointings[i].exptime, /nan, bin=bin, /over, color=150
		al_legend, box=0,/right, string(median(pointings.exptime), form='(F4.1)') + ' sec.'+ '!C' + string(mean(pointings.exptime), form='(F4.1)') + ' sec.'
	
		smultiplot
		if t eq 1 then !y.title = 'Time Slewing' else !y.title=''
		plothist, pointings.timeslewing, /nan, xr=xr,bin=bin, xtitle='Time (seconds)';, /ylog
		plothist, pointings[i].timeslewing, /nan, bin=bin, /over, color=150
		al_legend, box=0,/right,  string(median(pointings.timeslewing), form='(F4.1)') + ' sec.' + '!C' + string(mean(pointings.timeslewing < 300), form='(F4.1)') + ' sec.'
	endfor
		smultiplot, /def
	device, /close
	epstopdf, 'super_estimate_overheads.eps'
	set_plot, 'x'
	
	stop
END
