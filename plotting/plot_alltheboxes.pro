PRO plot_alltheboxes, ensemble, eps=eps
	common mearth_tools

	if file_test('alltheboxes.idl') eq 0 then begin
		for i=0, n_elements(possible_years) -1 do if n_elements(ensemble) eq 0 then ensemble = create_struct('YE'+string(format='(I02)', possible_years[i] mod 100), load_ensemble_boxes(year=possible_years[i])) else ensemble = create_struct(ensemble, 'YE'+string(format='(I02)', possible_years[i] mod 100), load_ensemble_boxes(year=possible_years[i]))
		save, filename='alltheboxes.idl', ensemble
	endif else restore, 'alltheboxes.idl'
	if ~keyword_set(ensemble) then ensemble = load_ensemble_boxes()
	cleanplot, /silent
	erase

	!p.charsize=0.8

	filename = 'alltheboxes.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=10, /inches, /color
	endif else xplot, ysize=1000, xsize=800

	n_durations = n_elements(ensemble.(0)[0].depth)
	smultiplot, /init, [n_tags(ensemble),n_durations], /rowmaj, ygap =0.001, xgap=0.002

	for j=0, n_tags(ensemble)-1 do begin
		n_durations = n_elements(ensemble.(j)[0].depth)
		unknown = ones(n_elements(ensemble.(j).lspm);ensemble.(j).lspm ne 1186 and ensemble.(j).lspm ne 3512 and ensemble.(j).lspm ne 3229 and ensemble.(j).lspm ne 1803
		for i=0, n_durations -1 do begin
			not_flare = ensemble.(j).n[i] gt 0
			defined = ensemble.(j).depth[i] ne 0 and ensemble.(j).depth_uncertainty[i] gt 0
			i_all = where(unknown and defined, n_boxes)
			i_notflare = where(unknown and not_flare and defined, n_boxes)
			gold = ensemble.(j).depth_uncertainty[i] lt 0.01 and ensemble.(j).rescaling[i] lt 1.2
			i_golden = where(unknown and not_flare and defined and gold, n_boxes)
			smultiplot
			loadct, 0, /silent
			if i eq (n_durations-1) then xtitle =goodtex('D/\sigma') else xtitle = ' '
			if i eq 4 then ytitle ="# of epochs" else ytitle = ' '
			if i eq 0 then title = string(possible_years[j], form='(I4)') else title = ' '
			plot, [0], xtitle=xtitle, ytitle=ytitle, title=title, /ylog, ys=3, xs=3, xr=[-1,1]*14, yr=[0.9, 1e6]
			plothist, ensemble.(j)[i_all].depth[i]/ensemble.(j)[i_all].depth_uncertainty[i], bin=0.1, /overplot, color=175
			plothist, ensemble.(j)[i_notflare].depth[i]/ensemble.(j)[i_notflare].depth_uncertainty[i], bin=0.1, /overplot

			loadct, 39, /sil
	;		plothist, ensemble[i_golden].depth[i]/ensemble[i_golden].depth_uncertainty[i], bin=0.1, /overplot, color=70
			oplot_gaussian, ensemble.(j)[i_notflare].depth[i]/ensemble.(j)[i_notflare].depth_uncertainty[i], bin=0.1, pdf=[0,1], color=250
			al_legend, box=0, string(format='(F3.1)', ensemble.(j)[0].duration[i]*24) + ' hours', charsize=0.6
		endfor
	endfor
	smultiplot, /def

	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

END
