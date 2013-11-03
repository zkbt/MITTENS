PRO plot_common_mode
	
	@mearth_dirs
	restore, 'common_mode/cm_0.25.idl'
	cm.common_mode = cm.flux
;	t = tag_names(cm)
;	for i=0, N_tags(cm)-1 do print, i, ' ', t[i]
	set_plot, 'ps'
	device, filename=plot_dir + 'common_mode_timeseries.eps', /enc, xsize=7.5, ysize=5, /inches
	plot_struct, cm, xaxis=cm.hjd + 2400000.5d, xtickunits='Time', tags=[30,16,17,19,20], ygap=0.01, psym=8, symsize=0.1, xs=3
	device, /close
	epstopdf, plot_dir+ 'common_mode_timeseries'
	loadct, 39
	plot_nd, eps=plot_dir + 'common_mode_matrix.eps', cm, tags=[30,16,17,19,20], dye=cm.flux, symsize=0.6, psym=8
	plot_nd, eps=plot_dir + 'common_mode_matrix_bw.eps', cm, tags=[30,16,17,19,20], dye=fltarr(n_elements(cm.(0))), symsize=0.6, psym=8

	epstopdf, plot_dir + 'common_mode_matrix_bw'
END