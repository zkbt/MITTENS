;+
; NAME:
;	xinspect
;
; PURPOSE:
;	
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	xinspect
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls xinspect.  When this
;		ID is specified, the death of the caller results in the death
;		of xinspect.
;
;	BLOCK:  Set this keyword to have XMANAGER block when this
;		application is registered.  By default the Xmanager
;               keyword NO_BLOCK is set to 1 to provide access to the
;               command line if active command 	line processing is available.
;               Note that setting BLOCK for this application will cause
;		all widget applications to block, not only this
;		application.  For more information see the NO_BLOCK keyword
;		to XMANAGER.
;
; OUTPUTS:
;
; OPTIONAL OUTPUT PARAMETERS:
;
; COMMON BLOCKS:
;
; SIDE EFFECTS:
;	Initiates the XMANAGER if it is not already running.
;
; RESTRICTIONS:
;
; PROCEDURE:
;	Create and register the widget and then exit.
;
; MODIFICATION HISTORY:
;	Created from a template written by: Steve Richards, January, 1991.
;-

PRO xinspect_ev, event

	; set up common variables, to keep track of throughout xinspect process
	common xinspect_common, child_ids, whatarewelookingat, xinspect_coordinate_conversions, xinspect_camera, selected_object
	COMPILE_OPT hidden	; prevent this sub-procedure from showing up in HELP

	; find the uservalue of the widget where the event happened
	WIDGET_CONTROL, event.id, GET_UVALUE = eventval	



	; if the event is unidentifiable, then return
	IF N_ELEMENTS(eventval) EQ 0 THEN RETURN

	; debug
	;help, event, eventval, /st

	; decide what to do, based on what kind of event it is
	CASE tag_names(event, /struct) of 
		'WIDGET_LIST': 	begin
					if strmatch(eventval[0], 'phased*') then begin
						whatwasclicked = 'phased'
						whatarewelookingat.mode = 'candidate'
						whatarewelookingat.i_candidate = event.index
						widget_control, xinspect_camera.boxes_list, set_list_select=-1
						process_with_candidate, whatarewelookingat.best_candidates[whatarewelookingat.i_candidate]
						xinspect_remake_plots
					endif else if strmatch(eventval[0], 'single*') then begin
						whatwasclicked = 'single'
						whatarewelookingat.mode = 'marple'
						whatarewelookingat.i_box = event.index
						widget_control, xinspect_camera.candidates_list, set_list_select=-1
						process_with_candidate, whatarewelookingat.best_boxes[whatarewelookingat.i_box]
						xinspect_remake_plots
				
					endif
				end
		'':		begin
					if n_elements(eventval) gt 1 then begin
						whatwasclicked = eventval[event.value]
					endif
				end
		'WIDGET_BUTTON': whatwasclicked = eventval
		'WIDGET_DRAW': begin
				if event.release gt 0 then return
				whatwasclicked = eventval
				end
	ENDCASE
	; debug
	;help, whatwasclicked

	if n_elements(whatwasclicked) gt 0 then begin
		print, 'whatwasclicked is ', whatwasclicked
		CASE whatwasclicked OF
			"draw": begin
				geometry = widget_info(event.id, /geom)
				wset, xinspect_camera.draw_window

				data_click = smulti_datacoord(event=event, coordinate_conversions=xinspect_coordinate_conversions, geometry=geometry)
				print, data_click
			;	help, xinspect_coordinate_conversions
				; use left mouse button to select objects
				if event.press eq 1 then begin
					plot_xinspect_population, data_click=data_click, counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions, selected_object=selected_object

					set_star, selected_object.star_dir
					xinspect_update_information_panel
					xinspect_update_lists, input_object=selected_object
					xinspect_remake_plots
				endif
			
				; use middle mouse button to zoom in
				if event.press eq 2 then begin
		;			xinspect_camera.counter += 1
		;			plot_xinspect_population, counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions
				endif

				; use right mouse button to change views
				if event.press eq 4 then begin
					xinspect_camera.counter += 1
					plot_xinspect_population, counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions
				endif
			end

			"orbital phase":	begin
							if event.select eq 1 then begin
								xlc_orbit, id=xlc_orbitbase, group=child_ids.xinspect
								child_ids.xlc_orbit = xlc_orbitbase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_orbit, /valid) then  widget_control, child_ids.xlc_orbit, /destroy
							endif
					end
			
			"time":		begin
							if event.select eq 1 then begin
								xlc_time, id=xlc_timebase, group=child_ids.xinspect
								child_ids.xlc_time = xlc_timebase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_time, /valid) then  widget_control, child_ids.xlc_time, /destroy
							endif
					end
			
			"rot. phase":	begin
							if event.select eq 1 then begin
								xlc_rotation, id=xlc_rotationbase, group=child_ids.xinspect
								child_ids.xlc_rotation = xlc_rotationbase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_rotation, /valid) then  widget_control, child_ids.xlc_rotation, /destroy
							endif
					end
			"Done": WIDGET_CONTROL, event.top, /DESTROY		;There is no need to
										;"unregister" a widget
										;application.  The
										;XManager will clean
										;the dead widget from
										;its list.
			
			ELSE: print, "no event handler yet!"		
		ENDCASE
	endif

END



PRO xinspect, GROUP = GROUP, BLOCK=block
	common xinspect_common
	common mearth_tools
	common this_star

	cleanplot
	device, decomposed=0
;===========================================================================================================================
;===========================================================================================================================
;===========================================================================================================================


;===========================================================================================================================
;===========================================================================================================================
;===========================================================================================================================

;*** If xinspect can have multiple copies running, then delete the following
;*** line and the comment for it.  Often a common block is used that prohibits
;*** multiple copies of the widget application from running.  In this case, 
;*** leave the following line intact.

IF(XRegistered("xinspect") NE 0) THEN RETURN		;only one instance of
							;the xinspect widget
							;is allowed.  If it is
							;already managed, do
							;nothing and return

IF N_ELEMENTS(block) EQ 0 THEN block=0

;*** Next the main base is created.  You will probably want to specify either
;*** a ROW or COLUMN base with keywords to arrange the widget visually.

xinspectbase = WIDGET_BASE(TITLE = "xinspect", /column)	;create the main base

;*** Here some default controls are built in a menu.  The descriptions of these
;*** procedures can be found in the xinspect_ev routine above.  If you would
;*** like to add other routines or remove any of these, remove them both below
;*** and in the xinspect_ev routine.


; eps = widget_button(outputs, uvalue='eps', value='save to EPS')
; png = widget_button(outputs, uvalue='png', value='save to PNG')
; blog = widget_button(outputs, uvalue='blog', value='post to blog')

plotting_frame = widget_base(xinspectbase, /row, /frame)

spawn, 'cat ' + star_dir + 'pos.txt', result1
spawn, 'cat ' + star_dir + 'lspm_obs.txt', result2
spawn, 'cat ' + star_dir + 'lspm_phys.txt', result3

skymap_draw = widget_draw(plotting_frame, xsize=500, ysize=500, uval='draw', /button_event)
information_panel = widget_text(plotting_frame, xsize=20, ysize=15, value=[result1, result2, result3])


explore_base = widget_base(plotting_frame, col=1, /frame, /base_align_cent)
	text = widget_label(explore_base, value='How do you want to explore?')
	explorecandidate_base = widget_base(explore_base, /col)
	exploresingle_base = widget_base(explore_base, /col)

text = widget_label(explorecandidate_base, value='Phased Candidates')
candidates_list = widget_list(explorecandidate_base, ysize=7, xsize=20)

text = widget_label(exploresingle_base, value='Interesting Single Events')
boxes_list = widget_list(exploresingle_base, ysize=7, xsize=20)




;thingstoplot_base = widget_base(plotting_frame, /row, /frame, /nonexclusive, /base_align_cent)

thingstoplot= {	values:['individual events', 'orbital phase', 'rotational phase', 'time', '#', 'D/sigma', 'correlations', 'periodogram', 'MarPLE'], $
		setvalues:[0,0,0,0,0,0,0,0,0]}

thingstoplot_buttons = cw_bgroup(plotting_frame, thingstoplot.values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='What do you want to plot?', /FRAME, uvalue=thingstoplot.values, uname='thingstoplot', set_val=thingstoplot.setvalues)


; opends9 = widget_base(xinspectbase, /column)
; imagepernight = widget_button(opends9, uvalue='ds9 [1 image]/night', value='ds9 [1 image]/night')
; imagesintransit = widget_button(opends9, uvalue='ds9 in-transit images', value='ds9 in-transit images')
; imagesneartransit = widget_button(opends9, uvalue='ds9 near-transit images', value='ds9 near-transit images')


; opends9_values = ['[1 image]/night', 'in-transit', 'near-transit']
; opends9 = cw_bgroup(xinspectbase, opends9_values, /COLUMN, LABEL_TOP='Open Images in ds9?', /FRAME, uvalue=opends9_values)



done = WIDGET_BUTTON(xinspectbase, value='Done', uvalue='Done') 

;draw = WIDGET_DRAW(xinspectbase, XSIZE = 256, YSIZE = 256) 
 
xinspect_variables = {xinspectbase:xinspectbase}


;*** Typically, any widgets you need for your application are created here.
;*** Create them and use xinspectbase as their base.  They will be realized
;*** (brought into existence) when the following line is executed.

WIDGET_CONTROL, xinspectbase, /REALIZE			;create the widgets
							;that are defined
 WIDGET_CONTROL, skymap_draw, GET_VALUE = draw_window 

xinspect_camera = {draw_window:draw_window, counter:0, information_panel:information_panel,  boxes_list:boxes_list, candidates_list:candidates_list, thingstoplot_buttons:thingstoplot_buttons}
wset, draw_window
lspm = fix(stregex(/ext, stregex(/ext, star_dir(), 'ls[0-9]+'), '[0-9]+')) 
plot_xinspect_population, coordinate_conversions=xinspect_coordinate_conversions
;plot_skymap, lspm

;orb. phase

; ;Obtain the window index. if thingstoplot_setvalues[1] then xlc_orbit, group=child_ids.xinspect

; WIDGET_CONTROL, draw, GET_VALUE = index 
;  
; ;Set the new widget to be the current graphics window 
; WSET, index 

child_ids = {xlc_orbit:0, xlc_time:0, xlc_rotation:0, xinspect:xinspectbase}




XManager, "xinspect", xinspectbase, $			;register the widgets
		EVENT_HANDLER = "xinspect_ev", $	;with the XManager
		GROUP_LEADER = GROUP, $			;and pass through the
		NO_BLOCK=(NOT(FLOAT(block)))		;group leader if this
							;routine is to be 
							;called from some group
							;leader.

xinspect_update_information_panel
xinspect_update_lists
xinspect_remake_plots

END ;==================== end of xinspect main routine =======================
