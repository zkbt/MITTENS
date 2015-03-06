PRO xinspect_remake_plots
	common xinspect_common
	common mearth_tools
	widget_control, xinspect_camera.thingstoplot_buttons, get_uvalue=options
	widget_control, xinspect_camera.thingstoplot_buttons, get_value=selectedness
	print, options, selectedness
	for i=0, n_elements(options)-1 do begin
		mprint, tab_string, doing_string, 'updating plot for ', options[i]
		case options[i] of
			'individual events': begin
				if widget_info(child_ids.xlc_event, /valid) then widget_control, child_ids.xlc_event, /destroy
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  and file_test(star_dir() + 'cleaned_lc.idl') then begin
					xlc_event, id=xlc_eventbase, group=child_ids.xinspect
					child_ids.xlc_event = xlc_eventbase
				endif
			end
			'orbital phase': begin
				if widget_info(child_ids.xlc_orbit, /valid) then  widget_control, child_ids.xlc_orbit, /destroy
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					xlc_orbit, id=xlc_orbitbase, group=child_ids.xinspect
					child_ids.xlc_orbit = xlc_orbitbase
				endif
			end
			'rotational phase': begin
				if widget_info(child_ids.xlc_rotation, /valid) then  widget_control, child_ids.xlc_rotation, /destroy
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					xlc_rotation, id=xlc_rotationbase, group=child_ids.xinspect
					child_ids.xlc_rotation = xlc_rotationbase
				endif
			end
			'time':begin
				if widget_info(child_ids.xlc_time, /valid) then  widget_control, child_ids.xlc_time, /destroy
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					xlc_time, id=xlc_timebase, group=child_ids.xinspect
					child_ids.xlc_time = xlc_timebase
				endif
			end
			'#': begin
				if widget_info(child_ids.xlc_obsn, /valid) then  widget_control, child_ids.xlc_obsn, /destroy
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					xlc_obsn, id=xlc_obsnbase, group=child_ids.xinspect
					child_ids.xlc_obsn = xlc_obsnbase
				endif
			end
			'D/sigma': begin
				;if widget_info(child_ids.xlc_orbit, /valid) then wdelete, 4
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					cleanplot, /silent
					xplot, 4, xsize=1000, ysize=300
					plot_boxes
				endif
			end
			'correlations': begin
				;if widget_info(child_ids.xlc_orbit, /valid) then wdelete, 5
				if selectedness[i] eq 1 and file_test(star_dir() + 'cleaned_lc.idl')  then begin
					cleanplot, /silent
					xplot, 5, xsize=1000, ysize=500
					plot_residuals
				endif
			end
			else:
		endcase
	endfor
END