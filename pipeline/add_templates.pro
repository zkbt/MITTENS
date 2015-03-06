FUNCTION add_templates, input_templates, residuals

	templates = input_templates
	; setup environment
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	restore, star_dir + 'target_lc.idl'
	restore, star_dir+ 'ext_var.idl'

	ev_structure_tag_names = tag_names(ext_var) 
	for i=1, n_elements(optional_ev_tags)-1 do begin
		i_ev_temp = where(ev_structure_tag_names eq optional_ev_tags[i])
		; throw out external variables that don't vary!
		if stddev(ext_var.(i_ev_temp)) gt 0 then begin
			rank_cor = r_correlate(ext_var.(i_ev_temp), residuals)
			if rank_cor[1] lt 1e-3 then begin
	;			plot, ext_var.(i_ev_temp), residuals, psym=1, title=string(r_correlate(ext_var.(i_ev_temp), residuals), form='(A,A)') + '   ' + optional_ev_tags[i]
				if n_elements(i_ev) eq 0 then i_ev = i_ev_temp else i_ev = [i_ev, i_ev_temp] 
			endif
		endif
	endfor
	for i=0, n_elements(i_ev)-1 do if total(finite(ext_var.(i_ev[i]))) gt 2 then templates = create_struct(templates, ev_structure_tag_names[i_ev[i]], float(ext_var.(i_ev[i])))
	return, templates
END