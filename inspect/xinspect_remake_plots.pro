PRO xinspect_remake_plots
	common xinspect_common
	common mearth_tools
	widget_control, xinspect_camera.thingstoplot_buttons, get_uvalue=options
	widget_control, xinspect_camera.thingstoplot_buttons, get_value=selectedness
;thingstoplot= {	values:['individual events', 'orbital phase', 'rotational phase', 'time', '#', 'D/sigma', 'correlations', 'periodogram', 'MarPLE'], $
	print, options, selectedness
	for i=0, n_elements(options)-1 do begin
		mprint, tab_string, doing_string, 'updating plot for ', options[i]
		case options[i] of
			'orbital phase': begin
				if widget_info(child_ids.xlc_orbit, /valid) then  widget_control, child_ids.xlc_orbit, /destroy
				if selectedness[i] eq 1 then begin
					xlc_orbit, id=xlc_orbitbase, group=child_ids.xinspect
					child_ids.xlc_orbit = xlc_orbitbase
				endif
			end
	;		'rotational phase':begin
	;			xlc_rotation, id=xlc_rotationbase, group=child_ids.xinspect
	;			child_ids.xlc_rotation = xlc_rotationbase
	;		end
			'time':begin
				if widget_info(child_ids.xlc_time, /valid) then  widget_control, child_ids.xlc_time, /destroy
				if selectedness[i] eq 1 then begin
					xlc_time, id=xlc_timebase, group=child_ids.xinspect
					child_ids.xlc_time = xlc_timebase
				endif
			end
			else:
		endcase
	endfor
END