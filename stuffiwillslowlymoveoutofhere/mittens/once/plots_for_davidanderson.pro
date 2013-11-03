PRO plots_for_davidanderson
	set_plot, 'ps'
	common mearth_tools
	if ~keyword_set(cutoff) then cutoff = 7
	filename ='population/survey_sensitivity_'
	if keyword_set(trigger) then filename += 'trigger_'
	if keyword_set(year) then filename += 'ye'+string(format='(I02)', year) + '_'
	if keyword_set(tel) then filename += 'te'+string(format='(I02)', tel)+ '_'
	if keyword_set(lspm) then filename +='ls'+string(format='(I04)', lspm)+ '_'
	filename += strcompress(/remo, cutoff) + 'cutoff'
	filename += '.idl'
	f = file_search(filename)
	restore, f
	cleanplot
	
	!p.charthick=3
	
	!x.thick=3
	!y.thick=3	
	file_mkdir, 'fordavidanderson'
	label = 'fordavidanderson/';+rw(cutoff)+'sigma_'
	if keyword_set(trigger) then label += 'trigger_'
	loadct, 0, /silent
	!x.thick=1.5
	!y.thick=1.5
	!p.charthick=1.5
	i = where(cloud.radius lt 0.35)
	device, filename=label+'radii.eps', /encapsulated, /color, /inches, xsize=10.0, ysize=6
		plot, [0],xcharsize=2, ycharsize=2, thick=8, xthick=3, ythick=3, xtitle='Stellar Radius (solar radii)', ytitle='# of Stars Observed', ymargin=[10,5], xmargin=[15, 5], xrange=[0.08, 1.0], /nodata,  yr=[0,500]
		loadct, 39
		plothist, /over, color=250, cloud[i].radius, bin=0.05, xcharsize=2, ycharsize=2, thick=6
		
	device, /close
	epstopdf, label+'radii.eps'

	performance_plots, /eps, xr=[julday(1,1,2008) + 240, julday(1,1,2012) + 180] - 2400000L
	file_copy, 'performance_plot.pdf', 'fordavidanderson/performance_plot.pdf', /allow

 	marpleplot_cleanrms, /eps, /one 
	file_copy, 'oneyear_marpleplot_cleanrms.pdf', 'fordavidanderson/oneyear_cleanrms.pdf', /allow

 	marpleplot_rms, /eps, /one 
	file_copy, 'oneyear_marpleplot_rms.pdf', 'fordavidanderson/oneyear_rms.pdf'	, /allow

	marpleplot_cmdemo, nights=55987.0 +[0., 1., 3.0], /eps, /squashed
	file_copy, 'marpleplot_cmdemo.pdf', 'fordavidanderson/cmdemo.pdf'	, /allow

END