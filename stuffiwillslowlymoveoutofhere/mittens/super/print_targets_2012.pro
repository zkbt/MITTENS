PRO print_targets_2012, stars, jason, i_max, spot=spot, dontsubtract=dontsubtract, n_tel=n_tel

	filename='prioritized_2012_'+rw(n_tel)
	if keyword_set(spot) then filename+='_spotboost'
	if keyword_set(dontsubtract) then filename += '_ignoringpast'
	filename += '.txt'
	roughs = load_rough_fits()
	openw, lun, filename, /get_lun, width=1000
	printf, lun, 'estimate the first ', rw(i_max), ' stars can be observed in one season, using ', rw(n_tel), ' telescopes each'
	for i=0, n_elements(stars)-1 do begin
		obs_in_years = intarr(4)
		i08 = where(roughs.ls eq stars[i].obs.lspm and roughs.ye eq 08, n)
		if n gt 0 then n08 = total(roughs[i08].summary_sin.n_points, /int) else n08 = 0
		i09 = where(roughs.ls eq stars[i].obs.lspm and roughs.ye eq 09, n)
		if n gt 0 then n09 = total(roughs[i09].summary_sin.n_points, /int) else n09 = 0
		i10 = where(roughs.ls eq stars[i].obs.lspm and roughs.ye eq 10, n)
		if n gt 0 then n10 = total(roughs[i10].summary_sin.n_points, /int) else n10 = 0
		i11 = where(roughs.ls eq stars[i].obs.lspm and roughs.ye eq 11, n)
		if n gt 0 then n11 = total(roughs[i11].summary_sin.n_points, /int) else n11 = 0
	;	if max([n08,n09,n10,n11]) gt 1000 then continue
		if i le i_max then priority = 7 else if i le i_max*2 then priority = 6 else priority = 5
		printf, lun,  string(form='(I4)', stars[i].obs.lspm), string(form='(I4)', priority), $
			string(form='(F7.1)', jason[i].distance), string(form='(F7.1)', jason[i].distance_originally_adopted), string(form='(F7.1)', 1.0/jason[i].pi_literature), $
			 string(form='(F7.3)',jason[i].radius_new), string(form='(F7.3)', jason[i].radius_old), $
			string(form='(F7.2)', jason[i].flat_rescaling), string(form='(F7.2)', jason[i].sin_rescaling), $
			string(form='(F9.1)',stars[i].cost/stars[i].triggered_ps600[2]), string(form='(F9.1)',stars[i].cost/stars[i].triggered_ps300[2]), $
			string(form='(I7)', n08), string(form='(I7)', n09), string(form='(I7)', n10), string(form='(I7)', n11)
	endfor
	close, lun
	free_lun, lun
	spawn, 'cat ' + filename
	

END