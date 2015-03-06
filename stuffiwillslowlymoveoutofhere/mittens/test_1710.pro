PRO test_1710, png=png
	set_star, 1710, 12, /comb
	;explore_pdf, /octo
	
	lc_plot, /time, /phased, /binned, /eps, scale=0.02, png=png, n_bins=200
;	lc_plot, /time, /phased, /eps, scale=0.025
	xplot
	restore, star_dir() + 'variability_lc.idl'
	periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1, 100], sin_params=sin_params
	lc_plot, /time, /phased, sin=sin_params, /eps, symsize=0.2, /exter ,charsize=0.9, scale=0.02, png=png
END