;+
; NAME:
;	xinspect
;
; PURPOSE:
;	This is the main GUI engine for exploring MEarth light curves of target stars, as well as interesting single transit events and periodic candidates.	
;
; CALLING SEQUENCE:
;	xinspect, [lspm]
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;	lspm (optional) = catalog number for a MEarth target (will pull up the best candidate or event for that star
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
; 	xinspect_common (things needed for xinspect)
;	mearth_tools
;	this_star
;
; MODIFICATION HISTORY:
;
;-

PRO xinspect_ev, event

	; set up common variables, to keep track of throughout xinspect process
	common xinspect_common, child_ids, whatarewelookingat, xinspect_coordinate_conversions, xinspect_camera, selected_object, last_clicked_object
	COMPILE_OPT hidden	; prevent this sub-procedure from showing up in HELP
	common this_star
	; find the uservalue of the widget where the event happened
	WIDGET_CONTROL, event.id, GET_UVALUE = eventval	

	; if the event is unidentifiable, then return
	IF N_ELEMENTS(eventval) EQ 0 THEN RETURN

	; debug
	;help, event, eventval, /st
	lspm = lspm_info.lspmn
	; decide what to do, based on what kind of event it is
	CASE tag_names(event, /struct) of 

		; if you clicked on one of the lists (of either phased or single event candidates)
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
		; if the structure is generic, just pass the value onwards
		'':		begin
					if n_elements(eventval) gt 1 then begin
						whatwasclicked = eventval[event.value]
					endif
				end		
		; if it was button pressed, pass the button onward
		'WIDGET_BUTTON': whatwasclicked = eventval
		; if the draw window was clicked, pass that onward
		'WIDGET_DRAW': begin
				if event.release gt 0 then return
				whatwasclicked = eventval
				end
	ENDCASE
	

	; skip event handling if nothing was clicked
	if n_elements(whatwasclicked) gt 0 then begin

		; handle events for the different possible options of things you might have clicked
		CASE whatwasclicked OF

			; if you clicked somewhere on the draw window, handle the event!
			"draw": begin

				; get the geometry of the drawing window
				geometry = widget_info(event.id, /geom)

				; make sure that any plotting action to follow will go in the drawing window
				wset, xinspect_camera.draw_window

				; feed the mouse click event and the window geometry in to be converted into data coordinates
				data_click = smulti_datacoord(event=event, coordinate_conversions=xinspect_coordinate_conversions, geometry=geometry)

				; if we're in the middle of zooming, pretend it was the middle button that was pressed
				if event.press gt 0 and xinspect_camera.setting_zoom_right then event.press = 2
				if event.release gt 0 and xinspect_camera.setting_zoom_right then event.release = 2

				;===========================================
				; selecting an object and highlight it in on the population plot
				;===========================================
				; if the left button is pressed, select a point and replot
				if event.press eq 1 then begin
				
					; plot the population, feeding in the data click, which will be converted into a selected object
					plot_xinspect_population,lspm, data_click=data_click, counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions, selected_object=selected_object, xrange=xinspect_camera.zoom_xrange, yrange=xinspect_camera.zoom_yrange

					; set the current star directory to be the selected object
					set_star, selected_object.star_dir

					; update the information panel, candidates lists, and plots to incorporate the new selected object
					xinspect_update_lists, input_object=selected_object
					xinspect_update_information_panel
					xinspect_remake_plots
				endif
			
				;===========================================
				; setting custom zoom range
				;===========================================
				; use middle mouse button to zoom in
				if event.press eq 2 then begin
					if xinspect_camera.setting_zoom_left eq 0 and xinspect_camera.setting_zoom_right eq 0 then begin
						; zoom is pressed for the first time
						xinspect_camera.setting_zoom_left = 1
						xinspect_camera.setting_zoom_right = 0
					endif
				endif

				; if the left edge of the zoom window has already be set, then ask for the right side
				if xinspect_camera.setting_zoom_right then begin
					; when the mouse button is pushed
					if event.press gt 0 then begin
						if n_tags(data_click) eq 0 then return
						; draw crosshar
						plots, data_click.x, data_click.y, psym=1, symsize=4, thick=3, color=70
	
						; set the right side of the xrange to the mouse click
						xinspect_camera.zoom_xrange[1] = data_click.x
						xinspect_camera.zoom_yrange[1] = data_click.y
						oplot_box, xinspect_camera.zoom_xrange, xinspect_camera.zoom_yrange, thick=3, color=70
						print,  xinspect_camera.zoom_xrange, xinspect_camera.zoom_yrange
						; prevent freaking out if zoomed xrange is reverse
						if xinspect_camera.zoom_xrange[0] gt xinspect_camera.zoom_xrange[1] then begin
							xinspect_camera.zoom_xrange = reverse(xinspect_camera.zoom_xrange)
						endif
						if xinspect_camera.zoom_yrange[0] gt xinspect_camera.zoom_yrange[1] then begin
							xinspect_camera.zoom_yrange = reverse(xinspect_camera.zoom_yrange)
						endif

						wait, 0.3
						xinspect_camera.setting_zoom_left=0
						xinspect_camera.setting_zoom_right=0
						plot_xinspect_population, lspm,counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions,  xrange=xinspect_camera.zoom_xrange, yrange=xinspect_camera.zoom_yrange
					endif
				endif
	
				; if we're starting to set an xrange zoom range, record the position of the click
				if xinspect_camera.setting_zoom_left then begin
					; when the button is pressed
					if event.press gt 0 then begin
						; draw crosshair
						plots, data_click.x, data_click.y, psym=1, symsize=4, thick=3, color=70
	
						; because smultiplot is set, outline which window is being used to set zoom range in thick line
						xbox = [!p.position[0], !p.position[2], !p.position[2],!p.position[0],!p.position[0]]
						ybox = [!p.position[1], !p.position[1], !p.position[3],!p.position[3],!p.position[1]]
						plots, /normal, xbox, ybox, thick=4, color=70
						; record the mouse click position
						xinspect_camera.zoom_xrange[0] = data_click.x
						xinspect_camera.zoom_yrange[0] = data_click.y

	;					; switch to picking the other side of the zoom range
						xinspect_camera.setting_zoom_left = 0
						xinspect_camera.setting_zoom_right = 1
					endif
				endif

				;===========================================
				; change what aspects of the population are plotted
				;===========================================
				; use right mouse button to change views
				if event.press eq 4 then begin
					xinspect_camera.counter += 1
					plot_xinspect_population, lspm, counter=xinspect_camera.counter, coordinate_conversions=xinspect_coordinate_conversions
					xinspect_camera.zoom_xrange = [0,0]
					xinspect_camera.zoom_yrange = [0,0]
				endif
			end
			
			
			;===========================================
			; toggle all the various possible plots on and off
			;===========================================			
			"individual events":	begin
							if event.select eq 1 then begin
								xlc_event, id=xlc_eventbase, group=child_ids.xinspect
								child_ids.xlc_event = xlc_eventbase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_event, /valid) then  widget_control, child_ids.xlc_event, /destroy
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

			"#":		begin
							if event.select eq 1 then begin
								xlc_obsn, id=xlc_obsnbase, group=child_ids.xinspect
								child_ids.xlc_obsn = xlc_obsnbase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_obsn, /valid) then  widget_control, child_ids.xlc_obsn, /destroy
							endif
					end
			
			"rotational phase":	begin
							if event.select eq 1 then begin
								xlc_rotation, id=xlc_rotationbase, group=child_ids.xinspect
								child_ids.xlc_rotation = xlc_rotationbase
							endif
							if event.select eq 0 then begin
								if widget_info(child_ids.xlc_rotation, /valid) then  widget_control, child_ids.xlc_rotation, /destroy
							endif
			end
			
			'D/sigma':begin
				if event.select eq 1 then begin
					cleanplot, /silent
					xplot, 4, xsize=1000, ysize=300
					plot_boxes
				endif
				if event.select eq 0 then begin
					wdelete, 4
				endif
			end
			
			'correlations':begin
				if event.select eq 1 then begin
					cleanplot, /silent
					xplot, 5, xsize=1000, ysize=300
					plot_residuals
				endif
				if event.select eq 0 then begin
					wdelete, 5
				endif
			end

			;===========================================
			; quit when done
			;===========================================
			"Done": WIDGET_CONTROL, event.top, /DESTROY		
			
			ELSE: print, "no event handler yet!"		
		ENDCASE
	endif

END


PRO xinspect, input_lspm, GROUP = GROUP, BLOCK=block


	; load up lots of necessary common blocks
	common xinspect_common
	common mearth_tools
	common this_star

	; tidy up plotting
	cleanplot
	device, decomposed=0

	; only allow one instance of xinspect to be running at time
	IF(XRegistered("xinspect") NE 0) THEN RETURN
	IF N_ELEMENTS(block) EQ 0 THEN block=0

	; create the main window of the xinspect GUI; give it a name
	xinspectbase = WIDGET_BASE(TITLE = "xinspect", /column)	
		; create a frame that will contain the draw window for plotting the population of stars (and maybe other stuff too)
		plotting_base = widget_base(xinspectbase, /row, /frame)
			; create the draw window that will contain plots
			skymap_draw = widget_draw(plotting_base, xsize=500, ysize=500, uval='draw', /button_event)
			; create an information panel to print text about the star (basic parameters, observations gathered, etc...)
			information_panel = widget_text(plotting_base, xsize=20, ysize=15)
		; create a frame to contain options for exploring different single-transits/candidates
		explore_base = widget_base(plotting_base, col=1, /frame, /base_align_cent)
			text = widget_label(explore_base, value='How do you want to explore?')
			; create frames to contain candidate/event lists
			explorecandidate_base = widget_base(explore_base, /col)
				; a list containing interesting candidates
				text = widget_label(explorecandidate_base, value='Phased Candidates')
				candidates_list = widget_list(explorecandidate_base, ysize=7, xsize=40)
			exploresingle_base = widget_base(explore_base, /col)
				; a list containing interesting single events
				text = widget_label(exploresingle_base, value='Interesting Single Events')
				boxes_list = widget_list(exploresingle_base, ysize=10, xsize=40)

	; a structure that keeps track of various plotting options
	thingstoplot= {	values:['individual events', 'orbital phase', 'rotational phase', 'time', '#', 'D/sigma', 'correlations'], setvalues:[0,0,0,0,0,0,0]}
	thingstoplot_buttons = cw_bgroup(plotting_base, thingstoplot.values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='What do you want to plot?', /FRAME, uvalue=thingstoplot.values, uname='thingstoplot', set_val=thingstoplot.setvalues)

	; a big button to close down xinspect when finished
	done = WIDGET_BUTTON(xinspectbase, value='Done', uvalue='Done') 

	; realize the widgety window 	
	WIDGET_CONTROL, xinspectbase, /REALIZE
	
	; figure out how to access the drawing window
	WIDGET_CONTROL, skymap_draw, GET_VALUE = draw_window 
	wset, draw_window
	
	; define a structure that sits in the common block accessible by all xinspect subprocedures
	xinspect_camera = {draw_window:draw_window, counter:0, information_panel:information_panel,  boxes_list:boxes_list, candidates_list:candidates_list, thingstoplot_buttons:thingstoplot_buttons, zoom_xrange:[0.0d, 0.0d], zoom_yrange:[0.0d, 0.0d], setting_zoom_left:0B, setting_zoom_right:0B}

	; define another common structure that contains the IDs of the various 
	child_ids = {xlc_orbit:0, xlc_event:0, xlc_time:0, xlc_obsn:0, xlc_rotation:0, xinspect:xinspectbase}


	if keyword_set(input_lspm) then set_star, input_lspm, /combined

	
	; grab the lspm number from the current directory
	lspm = fix(stregex(/ext, stregex(/ext, star_dir(), 'ls[0-9]+'), '[0-9]+')) 
	lspm = lspm[0]
	plot_xinspect_population, lspm, coordinate_conversions=xinspect_coordinate_conversions, selected_object=selected_object



	; register the widget with the xmanager
	XManager, "xinspect", xinspectbase, $			;register the widgets
		EVENT_HANDLER = "xinspect_ev", $	;with the XManager
		GROUP_LEADER = GROUP, $			;and pass through the
		NO_BLOCK=(NOT(FLOAT(block)))		;group leader if this
							;routine is to be 
							;called from some group
							;leader.

print, 'waiting a second to allow the xmanager to register what has happened'
wait, 2
					; update the information panel, candidates lists, and plots to incorporate the new selected object
					xinspect_update_lists, input_object=selected_object ; this seems to update
					xinspect_update_information_panel
					xinspect_remake_plots
					
					

END