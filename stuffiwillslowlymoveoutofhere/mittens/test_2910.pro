
PRO test_2910, png=png
	set_star, 2910, 12, /comb
	explore_pdf, /octo, /hide
	
	loadct, 0
	lc_plot, /time, /phased, /eps, png=png, hatlen=80, /binned, scale=0.012
	loadct, 0
	lc_plot, /time, /phased,/eps, png=png, hatlen=80, xr=[-6,6], label='_zoom', /binned, scale=0.012

	explore_pdf, /octo, /hide, 0.1

 	marpleplot_griddemo, 56290, name=star_dir(), png=png, yr=[0.015, -0.01], /eps, stretch=1.5
 	marpleplot_griddemo, 56254, name=star_dir(), png=png, yr=[0.015, -0.01], /eps, stretch=1.5

	explore_pdf, /octo, /hide, 1

 	marpleplot_griddemo, 56268, name=star_dir(), png=png, yr=[0.015, -0.01], /eps, stretch=1.5


;	lc_plot, /time, /phased, /eps, scale=0.025
;	xplot
;	restore, star_dir() + 'variability_lc.idl'
;	periodogram, variability_lc, /left, /right, /top, /bottom, period=[0.1, 100], sin_params=sin_params
;	lc_plot, /time, /phased, sin=sin_params, /eps, symsize=0.3, /exter ,charsize=0.9, scale=0.04, png=png



; set_star, 2854, 12, 1
; explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
; marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png
; 
; 
; set_star, 2854, 12, 2
; explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
; marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png
; 
; 
; set_star, 2854, 12, /comb
; explore_pdf, /hide, /octo, 0.1, 'ls2854/ye12/combined/'
; marpleplot_griddemo, 56279, /eps, name=star_dir(), png=png
; 



END