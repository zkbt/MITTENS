PRO future_mearth, remake=remake
	if file_test('future_mearth_data.idl') eq 0 or  keyword_set(remake) then begin 
		old = simulate_a_season(1, /actual, /phase);, errors=10)
		new = simulate_a_season(2, /para, /trig);, errors=10)
		save, filename='future_mearth_data.idl'
	endif else restore, 'future_mearth_data.idl' 


		; extrapolate to below 2 earth radii
		min_radius = old.radius_axis[min(where(old.period_sensitivity[0,*] gt 0))]
		i_below = where(old.radius_axis lt min_radius)
		i_calibrate = min(where(old.radius_axis ge min_radius))
		for i =0 , n_elements(old.period_axis)-1 do old.period_sensitivity[i, i_below] = old.period_sensitivity[i,i_calibrate]*(old.radius_grid[i,i_below]/min_radius)^6


		min_radius = new.radius_axis[min(where(new.period_sensitivity[0,*] gt 0))]
		i_below = where(new.radius_axis lt min_radius)
		i_calibrate = min(where(new.radius_axis ge min_radius))
		for i =0 , n_elements(new.period_axis)-1 do new.period_sensitivity[i, i_below] = new.period_sensitivity[i,i_calibrate]*(new.radius_grid[i,i_below]/min_radius)^6


	old.period_sensitivity *=4
	new.period_sensitivity *= 4;*2
	
	old.period_sensitivity = smooth(old.period_sensitivity, [3, 5])
	new.period_sensitivity = smooth(new.period_sensitivity, [3, 5])

	pop = simulate_a_population(old, /howard)
	pop.period *=3



	cleanplot
	filename = 'future_mearth.eps'
	set_plot, 'ps'
	device, filename=filename, /encap, /color, xsize=7.5, ysize=2.5, /inches, /cmyk

; xplot, ysize=1000, xsize=500
	
	!x.margin = [8,8]
	!y.margin = [4,4]
  	!p.charthick=2
	!p.charsize=0.6
  	!x.thick=2
  	!y.thick=2
	!y.range = [1.5,4]
	!x.range = [0.5, 20]
	c_charsize=0.5
	c_charthick = 2
	c_thick = 2

	smultiplot, /init, [3,1], colw=[1,1.5, 1]

	top = max(pop.period*new.period_sensitivity*(new.radius_grid gt min(!y.range))*new.dlogperiod_grid*new.dlogradius_grid)
	levels = findgen(101)/100*top

	enclosed_planets = reverse([0.2, 0.4, 0.6, 0.8, 1.0]);
;	enclosed_planets =	reverse([0.2, 0.4, 0.6, 0.8, 1.0, 1.2, 1.4, 1.6, 1.8, 2.0])

	smultiplot, /dox, /doy

	y = pop.period*old.period_sensitivity*old.dlogperiod_grid*old.dlogradius_grid
	y = y[reverse(sort(y))]
	cumulative = total(y, /cum)
	i_levels = value_locate(cumulative, enclosed_planets)
	valid = where(i_levels lt n_elements(y)-1, n_valid)
	labeled_levels = y[[i_levels[valid]]]
	labels = string(enclosed_planets, form='(F3.1)')
	labels[min(valid)] += ' planets/yr'	
	labels = '           '
  	loadct, 43, file='~/zkb_colors.tbl'
	contour, pop.period*old.period_sensitivity*(old.radius_grid gt min(!y.range))*old.dlogperiod_grid*old.dlogradius_grid, old.period_axis, old.radius_axis, /fill,levels=levels, xs=3, ys=3;
	loadct, 0
	if n_valid gt 0 then contour, /overplot, pop.period*old.period_sensitivity*old.dlogperiod_grid*old.dlogradius_grid, old.period_axis, old.radius_axis,levels=labeled_levels,  xs=3, ys=3,  c_thick=c_thick;c_annot=labels[valid],c_charsize=c_charsize, c_charthick=c_charthick,

	plot, old.period_axis, old.radius_axis, /noerase, xtitle='Planet Orbital Period (days)', ytitle='Planet Size (Earth radii)', /nodata, title='Planet Detection Rate with!CPrevious Strategy (MEarth by itself)', ys=3, xs=3
	plots, 1.58*[1,1], [2.65], psym=7, symsize=0.7, thick=5
	xyouts, 1.58, 2.612, '  GJ1214b', charsize=0.6, charthick=3
  
	smultiplot

	smultiplot, /dox, /doy


	y = pop.period*new.period_sensitivity*new.dlogperiod_grid*new.dlogradius_grid
	y = y[reverse(sort(y))]
	cumulative = total(y, /cum)
	i_levels = value_locate(cumulative, enclosed_planets)
	valid = where(i_levels lt n_elements(y)-1, n_valid)
	labeled_levels = y[[i_levels[valid]]]
	labels = string(enclosed_planets, form='(F3.1)')
	labels[min(valid)] += ' planets/yr'	
	;	labels = '           '

  	loadct, 43, file='~/zkb_colors.tbl'
	contour, pop.period*new.period_sensitivity*(new.radius_grid gt min(!y.range))*new.dlogperiod_grid*new.dlogradius_grid, new.period_axis, new.radius_axis, /fill, levels=levels, xs=3, ys=3;
	loadct, 0
	if n_valid gt 0 then contour, /overplot, pop.period*new.period_sensitivity*new.dlogperiod_grid*new.dlogradius_grid, new.period_axis, new.radius_axis,levels=labeled_levels,  xs=3, ys=3,  c_thick=c_thick;c_annot=labels[valid],c_charsize=c_charsize, c_charthick=c_charthick,
	plot, new.period_axis, new.radius_axis, /noerase, xtitle='Planet Orbital Period (days)', /nodata, title='Planet Detection Rate with!CProposed Strategy (MEarth + LCOGT)', ys=3, xs=3, ytickn = replicate(' ', 30)
	axis, yaxis=1, ys=3, xs=3, ytitle='Planet Size (Earth radii)'
;	plots, 1.58*[1,1], [2.6], psym=7, symsize=0.7, thick=3
;	xyouts, 1.58, 2.55, '  GJ1214b', charsize=0.5
	
	smultiplot, /def


 	device, /close
 	epstopdf, filename

stop
END