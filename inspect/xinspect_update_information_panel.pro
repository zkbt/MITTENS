FUNCTION stringify_mag, mag
	if mag ne 0.0 then return, string(form='(F5.2)', mag) else return, '???'
END

FUNCTION stringify_pi, pi, err
	if pi gt 0.000001 then return, string(form='(F5.3)', pi) + '+/-' + string(form='(F5.3)', err) else return, '???'
END


PRO inspect_update_information_panel
	common inspect_common
	root_directory = mo_dir()

	if file_test(root_directory + 'mo_info.idl') eq 0 then begin
		info_on_star = ["don't seem to have", "data on this", "this star"]
	endif else begin
		restore, root_directory + 'mo_info.idl'

	
		info_on_star = ['ls'+string(form='(I04)', mo_info.lspmn) + ' = ' + mo_info.bestname, $
				mo_info.ra_string + ' ' +  mo_info.dec_string, $
				rw(string(mo_info.ra, form='(F9.5)')) + ' ' + rw(string(mo_info.dec, form='(F+9.5)')), $
				'pm = ' + rw(string(mo_info.pmra, form='(F+9.3)')) + ' ' + rw(string(mo_info.pmdec, form='(F+9.3)')), $
				'pi = ' + stringify_pi(mo_info.plx, mo_info.e_plx), $
				' ref = ' + mo_info.r_plx, $
				'V_est = ' + stringify_mag(mo_info.vest)	, $
				'V = ' + stringify_mag(mo_info.v)	, $
				'R = ' + stringify_mag(mo_info.r)	, $
				'J = ' + stringify_mag(mo_info.j)	, $
				'H = ' + stringify_mag(mo_info.h)	, $
				'K = ' + stringify_mag(mo_info.k)	, $
				'mass = ' + string(mo_info.mass, form='(F4.2)'), $
				'radius = ' + string(mo_info.radius, form='(F4.2)'), $
				'teff = ' + string(mo_info.teff, form='(I4)')] 
		;t = tag_names(mo_info)
		;info_on_star = strarr(n_elements(t))
		;for i=0, n_elements(t) -1 do info_on_star[i] = string(t[i]) + ' = ' + rw(string(mo_info.(i)) )
	endelse

	if strmatch(star_dir(), '*combined*') then begin
		f = file_search([star_dir() + '../*/', star_dir() + '../*/*/'], /mark_dir, /test_dir)
		if f[0] ne '' then begin 
			for i=0, n_elements(f)-1 do begin
				if file_test(f[i] + 'observation_summary.idl') then begin
					restore, f[i] + 'observation_summary.idl'
					this_info_on_data = [f[i], '   ' + rw(observation_summary.n_observations)+ ' obs. on ' + rw(observation_summary.n_nights) + ' nights']
					if n_elements(info_on_data) eq 0 then info_on_data= this_info_on_data else info_on_data = [info_on_data,this_info_on_data]
				endif
			endfor
		endif else begin
			info_on_data = "seems to be none"
		endelse
	endif else begin
		if file_test(star_dir() + 'observation_summary.idl') then begin
			restore, star_dir() + 'observation_summary.idl'
			info_on_data = [star_dir(),  '   ' + rw(observation_summary.n_observations)+ ' obs. on ' + rw(observation_summary.n_nights) + ' nights']
		endif else begin
			info_on_data = "seems to be none"
		endelse
	endelse


	if n_elements(info_on_data) eq 0 then begin
		info_on_data = "seems to be none"
		widget_control, inspect_camera.candidates_list, set_value = '(nothing)'
		widget_control, inspect_camera.boxes_list, set_value = '(nothing)'
		widget_control, inspect_camera.thingstoplot_buttons, get_value=selectedness
		widget_control, inspect_camera.thingstoplot_buttons, set_value=selectedness*0
		widget_control, inspect_camera.thingstoplot_buttons, sensitive=0
	endif else widget_control, inspect_camera.thingstoplot_buttons, sensitive=1

	informative_text = ['THE STAR:', ' '+ info_on_star, '', 'THE DATA:', ' '+info_on_data]
	widget_control, inspect_camera.information_panel, set_value=informative_text	
END