FUNCTION stringify_mag, mag
	if mag ne 0.0 then return, string(form='(F5.2)', mag) else return, '???'
END

FUNCTION stringify_pi, pi, err
	if pi gt 0.000001 then return, string(form='(F5.3)', pi) + '+/-' + string(form='(F5.3)', err) else return, '???'
END


PRO xinspect_update_information_panel
	common xinspect_common
	root_directory = stregex(star_dir(), 'ls[0-9]+/', /ext)

	if file_test(root_directory + 'lspm_info.idl') eq 0 then begin
		info_on_star = ["don't seem to have", "data on this", "this star"]
	endif else begin
		restore, root_directory + 'lspm_info.idl'

	
		info_on_star = ['ls'+string(form='(I04)', lspm_info.lspmn) + ' = ' + lspm_info.bestname, $
				lspm_info.ra_string + ' ' +  lspm_info.dec_string, $
				rw(string(lspm_info.ra, form='(F9.5)')) + ' ' + rw(string(lspm_info.dec, form='(F+9.5)')), $
				'pm = ' + rw(string(lspm_info.pmra, form='(F+9.3)')) + ' ' + rw(string(lspm_info.pmdec, form='(F+9.3)')), $
				'pi_lit = ' + stringify_pi(lspm_info.lit_plx, lspm_info.lit_e_plx), $
				'pi_jas = ' + stringify_pi(lspm_info.jason_plx, lspm_info.jason_e_plx), $
				'V_est = ' + stringify_mag(lspm_info.vest)	, $
				'V = ' + stringify_mag(lspm_info.v)	, $
				'R = ' + stringify_mag(lspm_info.r)	, $
				'J = ' + stringify_mag(lspm_info.j)	, $
				'H = ' + stringify_mag(lspm_info.h)	, $
				'K = ' + stringify_mag(lspm_info.k)	, $
				'mass = ' + string(lspm_info.mass, form='(F4.2)'), $
				'radius = ' + string(lspm_info.radius, form='(F4.2)'), $
				'teff = ' + string(lspm_info.teff, form='(I4)')] 
		;t = tag_names(lspm_info)
		;info_on_star = strarr(n_elements(t))
		;for i=0, n_elements(t) -1 do info_on_star[i] = string(t[i]) + ' = ' + rw(string(lspm_info.(i)) )
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
		widget_control, xinspect_camera.candidates_list, set_value = '(nothing)'
		widget_control, xinspect_camera.boxes_list, set_value = '(nothing)'
		widget_control, xinspect_camera.thingstoplot_buttons, get_value=selectedness
		widget_control, xinspect_camera.thingstoplot_buttons, set_value=selectedness*0
		widget_control, xinspect_camera.thingstoplot_buttons, sensitive=0
	endif else widget_control, xinspect_camera.thingstoplot_buttons, sensitive=1

	informative_text = ['THE STAR:', ' '+ info_on_star, '', 'THE DATA:', ' '+info_on_data]
	widget_control, xinspect_camera.information_panel, set_value=informative_text	
END