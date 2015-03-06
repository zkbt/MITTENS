PRO estimate_costs, eps=eps, year=year, remake=remake

	cutoff_trigger = 5.5
	cutoff_phased = 7.5

	common mearth_tools
	if ~keyword_set(year) then year=11
	four_digit_year = (year mod 2000) + 2000
	; load up an observational summary for the 2011-2012 season
	if file_test( string((year mod 2000) + 2000, form='(I4)') + '_obs_summary.idl' ) then restore,  string((year mod 2000) + 2000, form='(I4)') + '_obs_summary.idl' else obs_summary = load_obs_summaries(ye=year)
	obs_summary = obs_summary[where(obs_summary.tel lt 10)]
	i_ast = where(obs_summary.astonly ne 0, n_ast, complement=i_planet)
	t_slew = 100.0
	t_read = 20.0
	; summarize the data gathered
	planobs = obs_summary[i_planet]
	n_total_planet_exposures = total(planobs.n_exposures)
	n_total_good_planet_exposures = total(planobs.n_goodexposures)
	n_total_good_planet_pointing = total(planobs.n_goodpointings)
	n_estimated_total_planet_pointings = total(planobs.n_exposures/planobs.nexp_per_pointing)
	printl, '==='
	print, 'In the MEarth '+string(four_digit_year, form='(I4)')+ '-' + string(four_digit_year+1, form='(I4)')+ ' season, we our budget for planet observations was:'
	print
	print, '  by "star"'
	print, string(form = '(I15)',total(planobs.n_goodpointings gt 1000)), ' stars with more than 1000 good pointings, and ', rw(string(form = '(I15)',total(planobs.n_goodpointings lt 1000))), ' stars with fewer than ...'
	print, string(form = '(I15)',total(planobs.n_goodpointings gt 500)), ' stars with more than 500 good pointings, and ', rw(string(form = '(I15)',total(planobs.n_goodpointings lt 500))), ' stars with fewer than ...'
	print, string(form = '(I15)',total(planobs.n_goodpointings gt 100)), ' stars with more than 100 good pointings, and ', rw(string(form = '(I15)',total(planobs.n_goodpointings lt 100))), ' stars with fewer than ...'
	print
	print, '  by "exposure"'
	print, string(form = '(I15)', total(obs_summary[i_ast].n_exposures)) , ' total exposures spent on the astrometric search'
	print, string(form = '(I15)', n_total_planet_exposures) , ' total exposures spent on the planet search'
	print, string(form = '(I15)', n_total_good_planet_exposures) , ' of which passed my data quality flags'
	print
	print, '  by "pointing"'
	print, string(form = '(I15)', total(obs_summary[i_ast].n_exposures/obs_summary[i_ast].nexp_per_pointing)) , ' (estimated) total pointings spent on the astrometric search'
	print, string(form = '(I15)', n_estimated_total_planet_pointings) , ' (estimated) total pointings spent on the planet search'
	print, string(form = '(I15)',n_total_good_planet_pointing), ' total pointings that I used in my planet search'
	print
	print, '  by "time"'	
	cost_per_star = (planobs.exptime+t_read*(planobs.nexp_per_pointing-1) + t_slew)*planobs.n_goodpointings/60.0/60.0/24.0
	print, string(form = '(F17.1)', total(cost_per_star)) , ' (estimated) straight telescope-days observing (including overheads)'
		
	print
	print,"  for an approximation, let's assume we have " , rw(string(form='(I15)', n_total_good_planet_pointing)) + ' pointings or '+rw(string(form = '(I15)', total(cost_per_star)))+ ' days to spend next year'
	printl, '==='
	print


	; look only at planet fields, calculate survey sensitivity; also, compile the sensitivity estimates
	star_dirs = strarr(n_elements(planobs))
	for i=0, n_elements(planobs)-1 do star_dirs[i] = make_star_dir(planobs[i].lspm, planobs[i].year, planobs[i].tel)

	if is_uptodate('population/'+ string((year mod 2000) + 2000, form='(I4)') + '_survey_sensitivity_trigger_'+string(cutoff_trigger, form='(F3.1)')+'cutoff.idl', 'obs_summary.idl') eq 0 then begin
		real_triggered_sensitivity = compile_sensitivity(cutoff_trigger, /trigger, star_dirs=star_dirs, cloud=triggered_per_star_sensitivity, year=year, remake=remake)
	endif else begin
		restore, 'population/'+ string((year mod 2000) + 2000, form='(I4)') + '_survey_sensitivity_trigger_'+string(cutoff_trigger, form='(F3.1)')+'cutoff.idl'
		real_triggered_sensitivity = sensitivity
		triggered_per_star_sensitivity = cloud
	endelse
	if is_uptodate('population/'+ string((year mod 2000) + 2000, form='(I4)') + '_survey_sensitivity_'+string(cutoff_phased, form='(F3.1)')+'cutoff.idl', 'obs_summary.idl') eq 0 then begin
		real_phased_sensitivity = compile_sensitivity(cutoff_phased, star_dirs=star_dirs, cloud=phased_per_star_sensitivity, year=year, remake=remake)
	endif else begin
		restore, 'population/'+ string((year mod 2000) + 2000, form='(I4)') + '_survey_sensitivity_'+string(cutoff_phased, form='(F3.1)')+'cutoff.idl'
		real_phased_sensitivity = sensitivity
		phased_per_star_sensitivity = cloud
	endelse
periods = real_triggered_sensitivity.period.grid  
	star = {phased:phased_per_star_sensitivity[0], triggered:triggered_per_star_sensitivity[0], obs:planobs[0], phased_ps300:fltarr(n_elements(radii)), phased_ps600:fltarr(n_elements(radii)), triggered_ps300:fltarr(n_elements(radii)), triggered_ps600:fltarr(n_elements(radii)), cost:0.0}

	i_temp300 = where(abs(real_phased_sensitivity.temp.grid - 300) lt 5)
	i_temp600 = where(abs(real_phased_sensitivity.temp.grid - 600) lt 5)
	phased_ps300 = fltarr(n_elements(planobs), n_elements(radii))
	phased_ps600 = phased_ps300
	triggered_ps300 = fltarr(n_elements(planobs),  n_elements(radii))
	triggered_ps600 = triggered_ps300

	for i=0, n_elements(planobs)-1 do begin
		i_phased = where(strmatch(phased_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_phased)
		i_triggered = where(strmatch(triggered_per_star_sensitivity.star_dir, star_dirs[i] + '*'), n_match_triggered)
	
		if n_match_phased gt 0 and n_match_triggered gt 0 then begin
		;	i_phased = i_phased[0]
			star.phased = phased_per_star_sensitivity[i_phased]
			star.triggered = triggered_per_star_sensitivity[i_triggered]
			star.phased_ps300 = mean(phased_per_star_sensitivity[i_phased].temp_detection[i_temp300,*], dim=1) > 0
			star.phased_ps600 = mean(phased_per_star_sensitivity[i_phased].temp_detection[i_temp600,*], dim=1) > 0
			star.triggered_ps300 = mean(triggered_per_star_sensitivity[i_triggered].temp_detection[i_temp300,*], dim=1) > 0
			star.triggered_ps600 = mean(triggered_per_star_sensitivity[i_triggered].temp_detection[i_temp600,*], dim=1) > 0
			star.obs = planobs[i]
			if n_elements(stars) eq 0 then stars = star else stars = [stars, star]
		endif
	endfor
	stars.cost = (planobs.exptime+t_read*(stars.obs.nexp_per_pointing-1) + t_slew)*stars.obs.n_goodpointings/60.0/60.0/24.0

	loadct, 0
	cleanplot
	xplot
	!x.style=3
	if keyword_set(eps) then begin
		set_plot, 'ps'
		perstar_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_perstarsensitivity.eps'
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
		perstar_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_perstarsensitivity_radius.eps'
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
		pph_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_npointings.eps'
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
		plot_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_exptime.eps'
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
		plot_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_radius.eps'
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
		plot_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_costperpointing.eps'
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
		plot_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_cost.eps'
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
		plot_filename = string(four_digit_year, form='(I4)')+ '_' + 'super_pph_distance.eps'
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
	save, filename='budget_'+string(four_digit_year, form='(I4)')+'.idl', stars, real_phased_sensitivity, real_triggered_sensitivity, cutoff_trigger, cutoff_phased
	o = stars.obs
	plot, o.ra, o.dec, /nodata, ys=3, xs=3
	for i=0, n_elements(o)-1 do plots, o[i].ra, o[i].dec, psym=8, symsize=sqrt(o[i].n_goodpointings*5./max(o.n_goodpointings))
END