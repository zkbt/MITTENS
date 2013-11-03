PRO make_marpleplots
	marpleplot_rms, /eps
	marpleplot_cleanrms, /eps
	marpleplot_rednoise, /eps
	marpleplot_candidates, /eps
	marpleplot_cmdemo, nights=55987.0 +[0., 1., 3,4,5], /eps  

	set_star, 3496, 11
	explore_pdf


	marpleplot_griddemo, /eps, 55987, name="LSPM J1527+3714" 
	marpleplot_comparerednoise, /eps
; set_star, 2242, 11 & marpleplot_griddemo, /eps, 55987 ;1030 pretty good too; also 3484 (0.31Rsun)
marpleplot_warmup, n=100, /eps        
; 	set_star, 2230,
; 
update_star, 1186, 8, 1, /leni, /re, /all
lc_to_pdf, /rema, timemachine=54950, /real
fold_boxes
; 
; set_star, 3512, 8, 8
; lc_to_pdf, /remake, timemachine=54949, /real  
; fold_boxes
END