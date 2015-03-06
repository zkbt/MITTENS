PRO test_3042, png=png
	set_star, 3042, 12, /comb
	explore_pdf, /octo, /hide
	
	loadct, 0
	lc_plot, /time, /phased, /binned, /eps, scale=0.02, png=png;, zoom=0.5
	loadct, 0
	lc_plot, /time, /phased, /binned, /eps, scale=0.02, png=png,xr=[-12,12], label='_zoom';, zoom=0.5


;	lc_plot, /time, /phased, /eps, scale=0.025
; 	xplot
; 	restore, star_dir() + 'variability_lc.idl'
; 	periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1, 100], sin_params=sin_params
; 	lc_plot, /time, /phased, sin=sin_params, /eps, symsize=0.2, /exter ,charsize=0.9, scale=0.02, png=png

	marpleplot_griddemo, 56272, /eps, name=star_dir(), png=png, yr=[0.011, -0.011]
	marpleplot_griddemo, 56208, /eps, name=star_dir(), png=png, yr=[0.011, -0.011]

END