PRO plot_simulated_2012_costs, eps=eps
	common mearth_tools

	restore, 'simulated_sensitivities_for_2012.idl'
	stars = simulated_stars

	loadct, 0
	cleanplot
	xplot
	!x.style=3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		perstar_filename = 'super_simulated_perstarsensitivity.eps'
		device, filename=perstar_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		ytitle= ' ' 
		if r eq 0 then ytitle='Planets/Star' else ytitle=' '

		plot, [0], charsize=0.7, xr=alog10([10, 10000]), yr=[0, max( stars.triggered_ps600)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, alog10(stars.obs.n_goodexposures), stars.phased_ps600[r], psym=1, xr=alog10([10, 10000]), color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , alog10(stars.obs.n_goodexposures), stars.triggered_ps600[r], psym=1, xr=alog10([10, 10000]), color=150, /over, errcolor=250, symsize=0.3
		loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		if r eq 2 then xtitle=goodtex('log_{10} [# of good MEarth pointings]') else xtitle=' '
		plot, [0], charsize=0.7, xr=alog10([10, 10000]), yr=[0, max(  stars.triggered_ps300)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, alog10(stars.obs.n_goodexposures), stars.phased_ps300[r], psym=1, xr=alog10([10, 10000]), color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , alog10(stars.obs.n_goodexposures), stars.triggered_ps300[r], psym=1, xr=alog10([10, 10000]), color=150, /over, errcolor=250, symsize=0.3
		loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, perstar_filename
	endif


loadct, 0
	cleanplot
	xplot
	!x.style=3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		perstar_filename = 'super_simulated_perstarsensitivity_radius.eps'
		device, filename=perstar_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		ytitle= ' ' 
		x = stars.phased.radius
		xr = [0.07, 0.37]
		if r eq 0 then ytitle='Planets/Star' else ytitle=' '

		plot, [0], charsize=0.7, xr=xr, yr=[0, max( stars.triggered_ps600)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars.phased_ps600[r], psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars.triggered_ps600[r], psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
		loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		if r eq 2 then xtitle=goodtex('Stellar Radius (solar radii)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars.triggered_ps300)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars.phased_ps300[r], psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars.triggered_ps300[r], psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
		loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, perstar_filename
	endif



	
	loadct, 0
	cleanplot
	xplot
	!x.style=3

	if keyword_set(eps) then begin
		set_plot, 'ps'
		pph_filename = 'super_simulated_pph_npointings.eps'
		device, filename=pph_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	i_ok = where(stars.obs.n_goodpointings gt 50)
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=alog10([10, 10000]), yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, alog10(stars[i_ok].obs.n_goodexposures), stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=alog10([10, 10000]), color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , alog10(stars[i_ok].obs.n_goodexposures), stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=alog10([10, 10000]), color=150, /over, errcolor=250, symsize=0.3
		loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('log_{10} [# of good MEarth pointings]') else xtitle=' '
		plot, [0], charsize=0.7, xr=alog10([10, 10000]), yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, alog10(stars[i_ok].obs.n_goodexposures), stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=alog10([10, 10000]), color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , alog10(stars[i_ok].obs.n_goodexposures), stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=alog10([10, 10000]), color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
		 if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, pph_filename
	endif

	!x.style=3

	if keyword_set(eps) then begin
		set_plot, 'ps'
		plot_filename = 'super_simulated_pph_exptime.eps'
		device, filename=plot_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		x = stars.obs.exptime*stars.obs.NEXP_PER_POINTING
		x = x[i_ok]

		xr = range(x)
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
	  if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('Open-Shutter Time per Pointing (seconds)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over,x, stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, plot_filename
	endif

	!x.style=3

	if keyword_set(eps) then begin
		set_plot, 'ps'
		plot_filename = 'super_simulated_pph_radius.eps'
		device, filename=plot_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		x = stars.phased.radius
		x = x[i_ok]

		xr = [0.07, 0.37]
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('Stellar Radius (solar radii)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over,x, stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, plot_filename
	endif	
	


	!x.style=3


	if keyword_set(eps) then begin
		set_plot, 'ps'
		plot_filename = 'super_simulated_pph_costperpointing.eps'
		device, filename=plot_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		x = stars.cost/stars.obs.n_goodpointings*24.0*60.0
		x = x[i_ok]
		xr = range(x)
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
	  if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('Cost per Pointing (minutes)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over,x, stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, plot_filename
	endif

if keyword_set(eps) then begin
		set_plot, 'ps'
		plot_filename = 'super_simulated_pph_cost.eps'
		device, filename=plot_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		x = stars.cost
		x = x[i_ok]
		xr = range(x)
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
	  if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('Total Cost (days)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over,x, stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, plot_filename
	endif




	if keyword_set(eps) then begin
		set_plot, 'ps'
		plot_filename = 'super_simulated_pph_distance.eps'
		device, filename=plot_filename, xsize=10, ysize=5, /inches, /color, /enc
	endif
	smultiplot, [n_elements(radii), 2], /init, /rowm, ygap=0.005, xgap = 0.005
	for r =0, n_elements(radii)-1 do begin
		smultiplot
		loadct, 0
		mk_grid = findgen(1000)/50
		mass_grid = delfosse(mk_grid)
		mk = interpol(mk_grid, mass_grid, stars.phased.mass)
		dm = stars.phased.k - mk
		x = 10*10^(0.2*dm)
		x = x[i_ok]

		xr = range(x)
		if r eq 0 then ytitle='Planets/Day/Star' else ytitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(stars[i_ok].triggered_ps600[4]/stars[i_ok].cost)], title=string(radii[r], form='(F3.1)') + ' Earth radii', ytitle=ytitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over, x, stars[i_ok].phased_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps600[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 600K', box=0, charsize=0.8
		smultiplot
		loadct, 0
		if r eq 2 then xtitle=goodtex('Distance (pc)') else xtitle=' '
		plot, [0], charsize=0.7, xr=xr, yr=[0, max(  stars[i_ok].triggered_ps300[4]/stars[i_ok].cost)], ytitle=ytitle, xtitle=xtitle, ys=3
		loadct, 59, file='~/zkb_colors.tbl'
		plot_binned, /quart , /over,x, stars[i_ok].phased_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, errcolor=250, symsize=0.3
		loadct, 55, file='~/zkb_colors.tbl'
		plot_binned, /quart , x, stars[i_ok].triggered_ps300[r]/stars[i_ok].cost, psym=1, xr=xr, color=150, /over, errcolor=250, symsize=0.3
				loadct, 0
  if r eq 2 then al_legend, /top, /left, 'ZAET = 300K', box=0, charsize=0.8
	endfor
	al_legend, box=0, goodtex(['blue = '+string(cutoff_phased, form='(F3.1)')+'\sigma phased', 'orange = '+string(cutoff_trigger, form='(F3.1)')+'\sigma single events,!C               with trigger']), charsize=0.6
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, plot_filename
	endif	

stop
END