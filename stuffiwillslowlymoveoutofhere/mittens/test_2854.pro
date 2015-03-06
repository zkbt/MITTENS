PRO test_2854, png=png
	set_star, 2854, 12, /comb
	explore_pdf, /octo, /hide
	
	lc_plot, /time, /phased, /binned, /eps, scale=0.04, png=png
;	lc_plot, /time, /phased, /eps, scale=0.025
	xplot
	restore, star_dir() + 'variability_lc.idl'
	periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1, 100], sin_params=sin_params
	lc_plot, /time, /phased, sin=sin_params, /eps, symsize=0.3, /exter ,charsize=0.9, scale=0.04, png=png

stop


set_star, 2854, 12, 1
explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png


set_star, 2854, 12, 2
explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png


set_star, 2854, 12, /comb
explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png




END