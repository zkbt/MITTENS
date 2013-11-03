FUNCTION load_sensitivity, gauss=gauss, star_dirs
	if not keyword_set(star_dirs) then star_dirs = subset_of_stars()
	if keyword_set(year) then ye = string(format='(I02)', year mod 100) else ye = '*'
	if keyword_set(tel) then te = string(format='(I02)', tel mod 100) else te = '*'


	common mearth_tools
	if keyword_set(gauss) then filename = 'gauss_sensitivity.idl' else filename = 'sensitivity.idl'
	f = file_search(star_dirs + '/injection_test/'+filename)  
  i = where(file_test(stregex(/ext, f, 'ls[0-9]+/ye[0-9]+/te[0-9]+/injection_test/') + 'gauss_sensitivity.idl'))
  help, i
  f = f[i]
	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	h = histogram(ls, reverse_indices=ri)
	restore, f[0]
	print, filename
  print, total(h), ' total estimates'
  print, total(h gt 0), ' unique stars'
	n_periods = 1951
	period_grid = findgen(n_periods)/100   + 0.5
	period_detection = fltarr(n_periods, n_elements(radii))

	temp_grid = findgen(n_periods)/n_periods*500+150
	temp_detection =  fltarr(n_periods, n_elements(radii))

	for i=0, n_elements(h)-1 do begin
	 ok = 1
		if h[i] gt 0 then begin
			for j=0, h[i]-1 do begin
  				restore, f[ri[ri[i]+j]]
  				ok = where(total(finite(sensitivity), 2))
  				temp = {periods:periods[ok], sensitivity:sensitivity[ok,*]};, uncertainty:sensitivity_uncertainty}
  				if j eq 0 then s = temp
  				if mean(temp.sensitivity) gt mean(s.sensitivity) then s = temp
  ;				print, ls[ri[ri[i]+j]]
  
			endfor
;			printl
      
			lspm_info = get_lspm_info(ls[ri[ri[i]]])
			for k =0, n_elements(radii)-1 do begin
				period_detection[*,k] += zinterpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), s.periods, period_grid)
				temp_detection[*,k] +=  interpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods))^0.5, temp_grid)
			endfor
;			!p.multi=[0,1,2]
;			plot, period_grid, period_detection[*,0], /xstyle, /ystyle, xrange=[0.6,10], xtitle='Period (days)', ytitle=goodtex('Expected Planet Yield if \eta_{M,Earth}=1'), /ylog, /xlog, yrange=[0.1, 100]
;			for m = 1, n_elements(radii)-1 do oplot, period_grid, period_detection[*,m], linestyle=m
;
;			al_legend, box=0, linestyle=indgen(n_elements(radii)), goodtex(string(format='(F3.1)', radii) + ' R_{Earth}'), /bottom, /left
;	
;			plot, temp_grid, temp_detection[*,0], /xstyle, /ystyle, xtitle='Zero-albedo Equilibrium Temperature', ytitle=goodtex('Expected Planet Yield if \eta_{M,Earth}=1'), /ylog, yrange=[0.1, 100], xrange=[250,max(temp_grid)]
;			for m = 1, n_elements(radii)-1 do oplot, temp_grid, temp_detection[*,m], linestyle=m
		endif		
	endfor
	
	file_mkdir, 'population'
  sensitivity = {period:{grid:period_grid, detection:period_detection}, temp:{grid:temp_grid, detection:temp_detection}}
	save, filename='population/survey_'+filename, sensitivity
  return, sensitivity

END 