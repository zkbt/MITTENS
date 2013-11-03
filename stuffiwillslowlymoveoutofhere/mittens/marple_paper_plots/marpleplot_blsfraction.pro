PRO marpleplot_blsfraction, eps=eps
	
	cleanplot
	restore, 'ensemble_of_blsfractions.idl'
	filename='marpleplot_blsfraction.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=3.5, ysize=2.5, /inches, /color
	endif
	!y.margin[0] = 5
	!x.margin[0] = 8
	!p.charsize=0.75
	loadct, 3

	bin =0.02
	thick=3
	i = where(cloud.rednoise ge 0 and cloud.rednoise lt 0.25, n)
	plothist, cloud[i].fraction_of_bls, bin=bin, /norm, xr=[0,1.3], thick=thick, xtitle=goodtex('(D_{phased}/\sigma_{phased [MarPLE]})/(D_{injected}/\sigma_{injected}) !C!B[ratio of detection significances]'), ytitle='# of MEarth target stars'
	vline, linestyle=1, color=0, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.25 and cloud.rednoise le .5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=100, /nan, bin=bin, /norm, thick=thick
	vline, linestyle=1, color=100, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=200, bin=bin, /norm, thick=thick
	vline, linestyle=1, color=200, median(cloud[i].fraction_of_bls), thick=2*thick/3.
	i = where(cloud.rednoise gt 0.25 and cloud.rednoise le .5, n)
	plothist, /over, cloud[i].fraction_of_bls, color=100, /nan, bin=bin, /norm, thick=thick
	i = where(cloud.rednoise ge 0 and cloud.rednoise lt 0.25, n)
	plothist, cloud[i].fraction_of_bls,  /nan, bin=bin, /norm, thick=thick, /over
	al_legend, /left, /top, color=[0,100,200], goodtex(['< 25% red noise', '25-50% red noise', '> 50% red noise']), box=0, linestyle=0, thick=3, charsize=0.6
	al_legend, /right, /top, goodtex('based on 5\times10^4!Cfake 2-4R_{!20S!3} planets!Cinjected into !Ceach star'  ), box=0, charsize=0.5
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

END