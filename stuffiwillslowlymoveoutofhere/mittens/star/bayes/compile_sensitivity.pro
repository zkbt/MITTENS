FUNCTION compile_sensitivity,  cutoff, year=year, tel=tel, lspm=lspm, radius_range=radius_range, remake=remake, cloud=cloud, star_dirs=star_dirs, trigger=trigger

	common mearth_tools
	if keyword_set(trigger) then the_dir_with_the_fake = fake_trigger_dir else the_dir_with_the_fake=fake_dir

	if ~keyword_set(star_dirs) then star_dirs = subset_of_stars(fake_trigger_dir+ 'injected_and_recovered.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range)
xplot	
;	star_dirs = star_dirs[where(long(stregex(/ext, stregex(/ext, star_dirs,  'ye[0-9]+'), '[0-9]+')) ne 11)]

	ls = long(stregex(/ext, stregex(/ext, star_dirs,  'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, star_dirs,  'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, star_dirs,  'te[0-9]+'), '[0-9]+'))

filename ='population/'+ string((year mod 2000) + 2000, form='(I4)') + '_survey_sensitivity_'
if keyword_set(trigger) then filename += 'trigger_'
if keyword_set(year) then filename += 'ye'+string(format='(I02)', year) + '_'
if keyword_set(tel) then filename += 'te'+string(format='(I02)', tel)+ '_'
if keyword_set(lspm) then filename +='ls'+string(format='(I04)', lspm)+ '_'
filename += string(cutoff, form='(F3.1)')+ 'cutoff'
filename += '.idl'
	print, filename
		h = histogram(ls, reverse_indices=ri)
	  print, total(h), ' total estimates'
 	 print, total(h gt 0), ' unique stars'
	period_min =0.5
	period_max = 20.0
	period_bin = 0.01
	n_periods = (period_max - period_min)/period_bin+1
	period_grid = findgen(n_periods)*period_bin + period_min
	period_detection = fltarr(n_periods, n_elements(radii))

	temp_grid = findgen(n_periods)/n_periods*850+150
	temp_detection =  fltarr(n_periods, n_elements(radii))

	droplet_template = {period_detection:period_detection, temp_detection:temp_detection, temp_window:fltarr(n_periods), temp_transitprob:fltarr(n_periods),  period_window:fltarr(n_periods),period_transitprob:fltarr(n_periods), star_dir:'', year_used:0, lspm:0, ra:0.0d, dec:0.0d, raj2000:0.0d, dej2000:0.0d, parallax:0.0, pmra:0.0d, pmdec:0.0d, v:0.0d, k:0.0d, mass:0.0d, radius:0.0d, logg:0.0d, lum:0.0d, sp:0.0d, teff:0.0d} 
	i_hasdata = where(h gt 0, n_hasdata)
	cloud = replicate(droplet_template, n_hasdata)
	for dummy=0, n_hasdata-1 do begin
		i = i_hasdata[dummy]
		ok = 1
	
		droplet = droplet_template
		if h[i] gt 0 then begin
			for j=0, h[i]-1 do begin
				set_star, ls[ri[ri[i]+j]], ye[ri[ri[i]+j]], te[ri[ri[i]+j]]
				droplet.lspm =  ls[ri[ri[i]+j]]
				droplet.year_used = ye[ri[ri[i]+j]]
				estimate_sensitivity, cutoff, remake=remake, trigger=trigger
				if file_test(star_dirs[ri[ri[i]+j]]+ the_dir_with_the_fake +  'sensitivity_cutoff' + string(format='(F04.1)', cutoff) + '.idl') eq 0 then begin
					nodataforthisstar = 1
					continue
				endif else nodataforthisstar =0 
				restore, star_dirs[ri[ri[i]+j]]+ the_dir_with_the_fake +  'sensitivity_cutoff' + string(format='(F04.1)', cutoff) + '.idl'	; taking the first year right now!
  				ok = where(total(finite(sensitivity), 2))
  				temp = {periods:periods[ok], sensitivity:sensitivity[ok,*], window:median(wfunction[ok,*], dim=2)};, uncertainty:sensitivity_uncertainty}
  				if j eq 0 then s = temp
  				if mean(temp.sensitivity) gt mean(s.sensitivity) then s = temp
			endfor
			if nodataforthisstar eq 1 then continue
			lspm_info = get_lspm_info(ls[ri[ri[i]]])
			copy_struct, lspm_info, droplet
			for k =0, n_elements(radii)-1 do begin
				droplet.period_detection[*,k] = zinterpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), s.periods, period_grid)
				period_detection[*,k] += zinterpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), s.periods, period_grid)
			
				droplet.temp_detection[*,k] =  interpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods))^0.5, temp_grid)
				temp_detection[*,k] +=  interpol(s.sensitivity[*,k]/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods))^0.5, temp_grid)
			endfor
			droplet.temp_window = interpol( temp.window, lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods))^0.5, temp_grid)
			droplet.period_window = interpol( temp.window,  s.periods, period_grid)
			droplet.temp_transitprob = interpol(1.0/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods), lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods))^0.5, temp_grid)
			droplet.period_transitprob = interpol(1.0/a_over_rs(lspm_info.mass, lspm_info.radius, s.periods),  s.periods, period_grid)
			droplet.star_dir = star_dir()

			cloud[dummy] = droplet
			!p.multi=[0,1,2]
			plot, period_grid, period_detection[*,0], /xstyle, /ystyle,xtitle='Period (days)', ytitle=goodtex('Expected Planet Yield if \eta_{M,Earth}=1'), /ylog, /xlog, yrange=[0.1, 100]; xrange=[0.6,20], 
			for m = 1, n_elements(radii)-1 do oplot, period_grid, period_detection[*,m], linestyle=m

			al_legend, box=0, linestyle=indgen(n_elements(radii)), goodtex(string(format='(F3.1)', radii) + ' R_{Earth}'), /bottom, /left
	
			plot, temp_grid, temp_detection[*,0], /xstyle, /ystyle, xtitle='Zero-albedo Equilibrium Temperature', ytitle=goodtex('Expected Planet Yield if \eta_{M,Earth}=1'), /ylog, yrange=[0.1, 100];, xrange=[250,max(temp_grid)]
			for m = 1, n_elements(radii)-1 do oplot, temp_grid, temp_detection[*,m], linestyle=m
; 			if question(/int, 'blerg') then stop
		endif else print, 'UHOH!'		
	endfor
	
	file_mkdir, 'population'
	sensitivity = {period:{grid:period_grid, detection:period_detection}, temp:{grid:temp_grid, detection:temp_detection}, radii:radii}

print, 'subset sensitivity saved to: ', filename
	save, filename=filename, sensitivity, cloud
;	save, filename='population/survey_'+filename, sensitivity
  return, sensitivity

END 