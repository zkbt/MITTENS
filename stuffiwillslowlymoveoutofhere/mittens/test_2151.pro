PRO test_2151, png=png
	set_star, 2151,  /comb
	explore_pdf, /octo, /hide
	
	loadct, 0
	lc_plot, /time, /phased, /binned, /eps, png=png, hatlen=80
	loadct, 0
	lc_plot, /time, /phased, /binned, /eps, png=png, hatlen=80, xr=[-24,24], label='_zoom'

 	marpleplot_griddemo, 55281, name=star_dir(), png=png, yr=[0.035, -0.02], /eps
 	marpleplot_griddemo, 55327, name=star_dir(), png=png, yr=[0.035, -0.02], /eps
 	marpleplot_griddemo, 55574, name=star_dir(), png=png, yr=[0.035, -0.02], /eps
 	marpleplot_griddemo, 55684, name=star_dir(), png=png, yr=[0.035, -0.02], /eps
 	marpleplot_griddemo, 55730, name=star_dir(), png=png, yr=[0.035, -0.02], /eps


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