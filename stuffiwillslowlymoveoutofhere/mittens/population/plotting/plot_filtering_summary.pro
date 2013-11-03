PRO plot_filtering_summary
	@mearth_dirs
	if file_test('filtering_summary.idl') then restore, 'filtering_summary.idl' else summarize_filtering
	loadct, 3
	t = tag_names(cloud)
	for i=0, N_tags(cloud)-1 do print, i, ' ', t[i]
	i = where(cloud.variability lt 0.05 and cloud.filtered_rms lt 0.025 and cloud.stellar_radius lt 0.35 and cloud.planet_1sigma gt 0)

	plot_nd, cloud[i], dye = cloud[i].stellar_temperature,  eps=plot_dir+'photometry_matrix.eps', psym=8, symsize=1
;	epstopdf, plot_dir + 'photometry_matrix'
	

	@make_plots_thick
	set_plot, 'ps'
	device, filename=plot_dir + 'filtering_summary.eps', xsize=6, ysize=6, /inches, /encapsulated
		!p.thick=4
		!p.charthick=2
		bin=0.2
		loadct, 39
		plothist, cloud[i].planet_1sigma, bin=bin, xtitle=goodtex('1\sigma Photometric Precision (Earth radii)'), ytitle='Number of Stars', ys=1, xrange=[0.9, 5.1], yrange=[0,130], title='Oct. 2010 - Apr. 2011'
		loadct, 39
		plothist, /overplot, bin=bin, thick=4, cloud[i].unfiltered_planet_1sigma, linestyle=1
		plothist, /overplot, bin=bin, thick=6, cloud[i].planet_1sigma, color=250
		legend, linestyle=[1,0], color=[0,250], thick=[4,6], ["Raw Light Curves", "Cleaned Light Curves"], /top, /right, box=0, charsize=1
	device, /close
	set_plot, 'x'
	epstopdf, plot_dir + 'filtering_summary'
END
