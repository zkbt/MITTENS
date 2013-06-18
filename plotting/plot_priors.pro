PRO plot_priors, priors, fit
		cleanplot, /silent
		xplot, 1, title=star_dir() + 'Priors for Systematics + Variability Parameters', xsize=500, ysize=250
		loadct, 39
	!p.multi=[0,2,1]
		i = where(priors.name ne 'UNCERTAINTY_RESCALING' and fit.solved)
		yr = reverse(range(fit[i].coef, fit[i].uncertainty)) < 0.03 
		yr = yr > (-0.03)

		i = where(priors.name ne 'UNCERTAINTY_RESCALING' and strmatch(priors.name, '*NIGHT*') eq 0 and fit.solved, M)
if m gt 1 then begin
		ploterror,  indgen(M)-0.1, priors[i].coef, priors[i].uncertainty, xs=3, yr=yr, xtitle='Parameter', ytitle='Value'
		hline, 0, line=1
		oploterror, indgen(M), fit[i].coef, fit[i].uncertainty, color=250, errcolor=250
		xyouts,   indgen(M), fit[i].coef +fit[i].uncertainty*1.5,  fit[i].name, orient=90, align=0
		al_legend, linestyle=[0,0], color=[0,250], ['prior', 'season fit'], box=0

	i = where(priors.name ne 'UNCERTAINTY_RESCALING' and strmatch(priors.name, '*NIGHT*') eq 1 and fit.solved, M)
		if M gt 1 then begin
			ploterror,  indgen(M)-0.1, priors[i].coef, priors[i].uncertainty, xs=3,  yr=yr, xtitle='Parameter', ytitle='Value'
			hline, 0, line=1
			oploterror, indgen(M), fit[i].coef, fit[i].uncertainty, color=250, errcolor=250
			xyouts,   indgen(M), fit[i].coef +fit[i].uncertainty*1.5,  fit[i].name, orient=90, align=0
			al_legend, linestyle=[0,0], color=[0,250], ['prior', 'season fit'], box=0
		endif
endif
END