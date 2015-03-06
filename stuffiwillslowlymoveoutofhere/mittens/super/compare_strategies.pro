PRO compare_strategies, eps=eps, hide=hide
	max_tel = 8
	hmp = replicate({period:0.0d, temperature:0.0d}, max_tel)
	mode = {phased:hmp, triggered:hmp}
	occurrence = {howard:mode, coolkoi:mode}
	strategy = {actual:occurrence,  parallaxes:occurrence};nohistory_and_parallaxes:occurrence, nohistory_and_spots_and_parallaxes:occurrence, spots_and_parallaxes:occurrence, 

	; occurrence rates of Cool KOIS, taking simple subset of stars				
	for t=1, max_tel do begin
		triggered_sens = simulate_a_season(errors=0, t, /actual, /trig)
		phased_sens = simulate_a_season(errors=0, t, /actual, /phase)
		triggered_sens.period_sensitivity = triggered_sens.period_sensitivity > phased_sens.period_sensitivity
		triggered_sens.temperature_sensitivity = triggered_sens.temperature_sensitivity > phased_sens.temperature_sensitivity

		if t eq 1 then begin
			coolkoi_pop = simulate_a_population(triggered_sens, /cool)
			howard_pop = simulate_a_population(triggered_sens, /howard)
		endif
		; actual from the past four years
		strategy.actual.coolkoi.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, coolkoi_pop, $
			label='actual_coolkois_triggered_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + ' telescopes per star!C     actual average of the past 4 years'))
		strategy.actual.howard.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, howard_pop, $
			label='actual_howard_triggered_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + ' telescopes per star!C     actual average of the past 4 years'))
		strategy.actual.coolkoi.phased[t-1] = howmanyplanets(hide=hide, phased_sens, coolkoi_pop, $
			label='actual_coolkois_phased_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + ' telescopes per star!C     actual average of the past 4 years'))
		strategy.actual.howard.phased[t-1] = howmanyplanets(hide=hide, phased_sens, howard_pop, $
			label='actual_howard_phased_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + ' telescopes per star!C     actual average of the past 4 years'))


; 		; using the cheapest of the parallax stars + spots
; 		triggered_sens = simulate_a_season(errors=0, t, /parallaxes, /trig, /spot)
; 		phased_sens = simulate_a_season(errors=0, t, /parallaxes, /phase, /spot)
; 		triggered_sens.period_sensitivity = triggered_sens.period_sensitivity > phased_sens.period_sensitivity
; 		triggered_sens.temperature_sensitivity = triggered_sens.temperature_sensitivity > phased_sens.temperature_sensitivity
; 
; 		strategy.spots_and_parallaxes.coolkoi.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, coolkoi_pop, $
; 			label='spots_and_parallaxes_coolkois_triggered_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C and using spots"))
; 		strategy.spots_and_parallaxes.howard.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, howard_pop, $
; 			label='spots_and_parallaxes_howard_triggered_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C and using spots"))
; 		strategy.spots_and_parallaxes.coolkoi.phased[t-1] = howmanyplanets(hide=hide, phased_sens, coolkoi_pop, $
; 			label='spots_and_parallaxes_coolkois_phased_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C and using spots"))
; 		strategy.spots_and_parallaxes.howard.phased[t-1] = howmanyplanets(hide=hide, phased_sens, howard_pop, $
; 			label='spots_and_parallaxes_howard_phased_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C and using spots"))
; 




		; using the cheapest of the parallax stars
		triggered_sens = simulate_a_season(errors=0, t, /parallaxes, /trig)
		phased_sens = simulate_a_season(errors=0, t, /parallaxes, /phase)
		triggered_sens.period_sensitivity = triggered_sens.period_sensitivity > phased_sens.period_sensitivity
		triggered_sens.temperature_sensitivity = triggered_sens.temperature_sensitivity > phased_sens.temperature_sensitivity

		strategy.parallaxes.coolkoi.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, coolkoi_pop, $
			label='parallaxes_coolkois_triggered_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars"))
		strategy.parallaxes.howard.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, howard_pop, $
			label='parallaxes_howard_triggered_'+rw(t)+'_', $
			poplabel='Howard et al.', $
			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars"))
		strategy.parallaxes.coolkoi.phased[t-1] = howmanyplanets(hide=hide, phased_sens, coolkoi_pop, $
			label='parallaxes_coolkois_phased_'+rw(t)+'_', $
			poplabel='the Cool KOIS', $
			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars"))
		strategy.parallaxes.howard.phased[t-1] = howmanyplanets(hide=hide, phased_sens, howard_pop, $
			label='parallaxes_howard_phased_'+rw(t)+'_', $
			poplabel='Howard et al.', $
			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars"))
; 


; 		; using the cheapest of the parallax stars
; 		triggered_sens = simulate_a_season(errors=0, t, /parallaxes, /trig, /dontsubtract)
; 		phased_sens = simulate_a_season(errors=0, t, /parallaxes, /phase, /dontsubtract)
; 		triggered_sens.period_sensitivity = triggered_sens.period_sensitivity > phased_sens.period_sensitivity
; 		triggered_sens.temperature_sensitivity = triggered_sens.temperature_sensitivity > phased_sens.temperature_sensitivity
; 
; 		strategy.nohistory_and_parallaxes.coolkoi.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, coolkoi_pop, $
; 			label='nohistory_and_parallaxes_coolkois_triggered_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past"))
; 		strategy.nohistory_and_parallaxes.howard.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, howard_pop, $
; 			label='nohistory_and_parallaxes_howard_triggered_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past"))
; 		strategy.nohistory_and_parallaxes.coolkoi.phased[t-1] = howmanyplanets(hide=hide, phased_sens, coolkoi_pop, $
; 			label='nohistory_and_parallaxes_coolkois_phased_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past"))
; 		strategy.nohistory_and_parallaxes.howard.phased[t-1] = howmanyplanets(hide=hide, phased_sens, howard_pop, $
; 			label='nohistory_and_parallaxes_howard_phased_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past"))
; 


; 		; using the cheapest of the parallax stars
; 		triggered_sens = simulate_a_season(errors=0, t, /parallaxes, /trig, /dontsubtract, /spot)
; 		phased_sens = simulate_a_season(errors=0, t, /parallaxes, /phase, /dontsubtract, /spot)
; 		triggered_sens.period_sensitivity = triggered_sens.period_sensitivity > phased_sens.period_sensitivity
; 		triggered_sens.temperature_sensitivity = triggered_sens.temperature_sensitivity > phased_sens.temperature_sensitivity
; 
; 		strategy.nohistory_and_spots_and_parallaxes.coolkoi.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, coolkoi_pop, $
; 			label='nohistory_and_spots_and_parallaxes_coolkois_triggered_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past!C and using spots"))
; 		strategy.nohistory_and_spots_and_parallaxes.howard.triggered[t-1] = howmanyplanets(hide=hide, triggered_sens, howard_pop, $
; 			label='nohistory_and_spots_and_parallaxes_howard_triggered_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('6\sigma triggered threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past!C and using spots"))
; 		strategy.nohistory_and_spots_and_parallaxes.coolkoi.phased[t-1] = howmanyplanets(hide=hide, phased_sens, coolkoi_pop, $
; 			label='nohistory_and_spots_and_parallaxes_coolkois_phased_'+rw(t)+'_', $
; 			poplabel='the Cool KOIS', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past!C and using spots"))
; 		strategy.nohistory_and_spots_and_parallaxes.howard.phased[t-1] = howmanyplanets(hide=hide, phased_sens, howard_pop, $
; 			label='nohistory_and_spots_and_parallaxes_howard_phased_'+rw(t)+'_', $
; 			poplabel='Howard et al.', $
; 			simlabel=goodtex('8\sigma phased threshold!C     '+rw(t) + " telescopes per star!C     prioritizing Jason's cheapest stars!C    ignoring our past!C and using spots"))
; ; 
; 



		if t le 1 then continue

		if keyword_set(eps) then begin
			set_plot, 'ps'
			device, filename='comparing_strategies.eps', /encapsulated, /color, xsize=8, ysize=8, /inches
		endif
		erase
		smultiplot, [n_tags(mode), n_tags(hmp)], /init, xgap=0.04, ygap=0.04, /rowmaj
		for i_mode=0, n_tags(mode)-1 do begin
			tags_mode = tag_names(mode)
			title_mode = tags_mode[i_mode]
			for i_whatmatters=0, n_tags(hmp) - 1 do begin
				smultiplot, /dox, /doy
				tags_matters = tag_names(hmp)
				title_matters = tags_matters[i_whatmatters]
				if i_mode eq 0 then ytitle='Planets per Year' else ytitle=''
			;	if i_whatmatters eq n_tags(hmp)-1 then 
				xtitle='Number of Telescopes per Star' ;else xtitle=''
				loadct, 39
				plot, [0], yr=[0.003, 2.0], /ylog, xr=[1,8], xs=3, ys=3, xtitle=xtitle, ytitle=ytitle, title=title_mode + '; assuming ' + title_matters + ' matters most'
				for i_strategy=0, n_tags(strategy)-1 do begin
					for i_occurrence=0, n_tags(occurrence)-1 do begin
						colors = findgen(n_tags(strategy))*255.0/n_tags(strategy)
						oplot, indgen(max_tel) +1, strategy.(i_strategy).(i_occurrence).(i_mode)[0:t-1].(i_whatmatters), linestyle=i_occurrence, color=colors[i_strategy], psym=-8, symsize=1, thick=2
					endfor
				endfor
				al_legend, /right, bottom=i_whatmatters eq 0, top=i_whatmatters ne 0, linestyle=indgen(n_tags(occurrence)), tag_names(occurrence)
				al_legend, top=i_whatmatters eq 0, bottom=i_whatmatters ne 0,/left, linestyle=0, color=colors, psym=-8, tag_names(strategy)
			endfor
		endfor
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, 'comparing_strategies.eps'
	endif

	endfor

	stop

END