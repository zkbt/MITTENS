;+
; NAME:
;	xlc_event
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual
;	implementation of the xlc_event widget.  Use a global search and
;	replace to replace the word "xlc_event" with the name of the routine
;	you would like to use.
;
;	All the comments with a "***" in front of them should be read, decided
;	upon and removed for your final copy of the xlc_event widget
;	routine.
;
; CATEGORY:
;	Widgets.
; ;
; CALLING SEQUENCE:
;	xlc_event
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls xlc_event.  When this
;		ID is specified, the death of the caller results in the death
;		of xlc_event.
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

;------------------------------------------------------------------------------
;	procedure xlc_event_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the xlc_event widget.  It is
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the xlc_event widget.  The tool menu choice routines are
;*** already installed.  This routine is required for the xlc_event widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------



PRO xlc_event_ev, event

	common xlc_event_common, xlc_event_camera, xlc_event_coordinate_conversions, xlc_event_select, xlc_event_selected_times, xlc_event_ds9, xlc_event_censored_exposures, xlc_event_censored_filenames, xlc_event_censorship
	@widget_geometries
	common this_star
	common mearth_tools

	COMPILE_OPT hidden	; Don't appear in HELP output unless HIDDEN keyword is specified.
	WIDGET_CONTROL, event.id, GET_UVALUE = eventval		;find the user value of the widget where the event occured

	; debugging
	;print_struct, event

	IF N_ELEMENTS(eventval) EQ 0 THEN thebuttonclicked = '' else begin

		; debugging
		;print, "eventval is : ", eventval
		if n_elements(eventval) gt 1 then begin
			thebuttonclicked = eventval[event.value]
		endif else thebuttonclicked = eventval
	endelse

	;debugging
	;print, 'thebuttonclicked is ', thebuttonclicked

	CASE thebuttonclicked OF
		; if clicking somewhere on the plotting window
		"draw": begin
			; get the geometry of the plotting window
			geometry = widget_info(event.id, /geom)

			; convert the click in the plotting window to data coordinates
			data_click = smulti_datacoord(event=event, coordinate_conversions=xlc_event_coordinate_conversions, geometry=geometry)

			print, data_click ;debugging

			; if the middle mouse button is pushed, start zooming in on the x-axis
			if event.press eq 2 then begin
				if ~xlc_event_camera.setting_zoom_left and ~xlc_event_camera.setting_zoom_right then xlc_event_camera.setting_zoom_left = 1
			endif


			;===========================================
			; setting custom zoom range
			;===========================================
			; if the left edge of the zoom window has already be set, then ask for the right side
			if xlc_event_camera.setting_zoom_right then begin
				; when the mouse button is pushed
				if event.press gt 0 then begin
					; draw line
					vline, data_click.x, thick=4
					; set the right side of the xrange to the mouse click
					xlc_event_camera.xrange[1] = data_click.x
					; say that we're zooming in
					widget_control, xlc_event_camera.message_label_id, set_val='Zooming in to ' + string(form='(F5.1)', xlc_event_camera.xrange[0]) + ' to ' + string(form='(F5.1)', xlc_event_camera.xrange[1])
					; prevent freaking out if selected xrange is reverse
					if xlc_event_camera.xrange[0] gt xlc_event_camera.xrange[1] then begin
						xlc_event_camera.xrange = reverse(xlc_event_camera.xrange)
					endif
				endif
				; when the mouse button is released
				if event.release gt 0 then begin
					xlc_event_camera.setting_zoom_right = 0
					widget_control, xlc_event_camera.message_label_id, set_val=''
				endif
			endif

			; if we're starting to set an xrange zoom range, record the position of the click
			if xlc_event_camera.setting_zoom_left then begin
				; when the button is pressed
				if event.press gt 0 then begin
					; draw line
					vline, data_click.x, thick=4
					; because smultiplot is set, outline which window is being used to set zoom range in thick line
					xbox = [!p.position[0], !p.position[2], !p.position[2],!p.position[0],!p.position[0]]
					ybox = [!p.position[1], !p.position[1], !p.position[3],!p.position[3],!p.position[1]]
					plots, /normal, xbox, ybox, thick=4
				endif
				; when the button is released
				if event.release gt 0 then begin
					; ask the user to set the rest of the zoom range
					widget_control, xlc_event_camera.message_label_id, set_val='Please pick the RIGHT side of your zoom range.'
					; switch to picking the other side of the zoom range
					xlc_event_camera.setting_zoom_left = 0
					xlc_event_camera.setting_zoom_right = 1
					; record the mouse click position
					xlc_event_camera.xrange[0] = data_click.x
				endif
			endif


			;===========================================
			; setting custom select range
			;===========================================
			; if the left edge of the select window has already be set, then ask for the right side
			if xlc_event_camera.setting_select_right then begin
				; when the mouse button is pushed
				if event.press gt 0 then begin
					if n_tags(data_click) eq 0 then return
					; draw crosshar
					plots, data_click.x, data_click.y, psym=1, symsize=2, thick=3

					; set the right side of the xrange to the mouse click
					xlc_event_camera.select_xrange[1] = data_click.x
					xlc_event_camera.select_yrange[1] = data_click.y

					oplot_box, xlc_event_camera.select_xrange, xlc_event_camera.select_yrange, thick=3
					print,  xlc_event_camera.select_xrange, xlc_event_camera.select_yrange
; 					; say that we're selecting in
; 					widget_control, xlc_event_camera.message_label_id, set_val='selecting in to ' + string(form='(F5.1)', xlc_event_camera.xrange[0]) + ' to ' + string(form='(F5.1)', xlc_event_camera.xrange[1])
					; prevent freaking out if selected xrange is reverse
					if xlc_event_camera.select_xrange[0] gt xlc_event_camera.select_xrange[1] then begin
						xlc_event_camera.select_xrange = reverse(xlc_event_camera.select_xrange)
					endif
					if xlc_event_camera.select_yrange[0] gt xlc_event_camera.select_yrange[1] then begin
						xlc_event_camera.select_yrange = reverse(xlc_event_camera.select_yrange)
					endif
				endif
				; when the mouse button is released
				if event.release gt 0 then begin
					xlc_event_camera.setting_select_right = 0
					widget_control, xlc_event_camera.message_label_id, set_val=''
				endif
			endif

			; if we're starting to set an xrange select range, record the position of the click
			if xlc_event_camera.setting_select_left then begin
				; when the button is pressed
				if event.press gt 0 then begin
					; draw crosshair
					plots, data_click.x, data_click.y, psym=1, symsize=2, thick=3

					; because smultiplot is set, outline which window is being used to set select range in thick line
					xbox = [!p.position[0], !p.position[2], !p.position[2],!p.position[0],!p.position[0]]
					ybox = [!p.position[1], !p.position[1], !p.position[3],!p.position[3],!p.position[1]]
					plots, /normal, xbox, ybox, thick=4
					; record the mouse click position
					xlc_event_camera.select_xrange[0] = data_click.x
					xlc_event_camera.select_yrange[0] = data_click.y
					xlc_event_camera.select_which = data_click.which
				endif
				; when the button is released
				if event.release gt 0 then begin
					; ask the user to set the rest of the select range
					widget_control, xlc_event_camera.message_label_id, set_val='Click UPPER RIGHT of points to select.'
					; switch to picking the other side of the select range
					xlc_event_camera.setting_select_left = 0
					xlc_event_camera.setting_select_right = 1

				endif
			endif


		end

		; jump to the previous event
		"previous": begin
			xlc_event_camera.whichevent -= 1
			if xlc_event_camera.whichevent le 0 then begin
				xlc_event_camera.whichevent = 0
				widget_control, xlc_event_camera.previous_id, sensitive=0
			endif else widget_control, xlc_event_camera.previous_id, sensitive=1
			if xlc_event_camera.whichevent lt (n_elements(xlc_event_camera.events)-1) then widget_control, xlc_event_camera.next_id, sensitive=1
			xlc_event_camera.select_xrange  = [0,0]
			xlc_event_camera.select_yrange  = [0,0]
		end
		; jump to the next event
		"next": begin
			xlc_event_camera.whichevent += 1
			if xlc_event_camera.whichevent ge (n_elements(xlc_event_camera.events)-1) then begin
				xlc_event_camera.whichevent = n_elements(xlc_event_camera.events) - 1
				widget_control, xlc_event_camera.next_id, sensitive=0
			endif else  widget_control, xlc_event_camera.next_id, sensitive=1
			if xlc_event_camera.whichevent gt 0 then widget_control, xlc_event_camera.previous_id, sensitive=1
			xlc_event_camera.select_xrange  = [0,0]
			xlc_event_camera.select_yrange  = [0,0]
		end



		; to zoom in vertically
		"scale + ": xlc_event_camera.scale *= 0.5
		; to zoom out vertically
		"scale - ": xlc_event_camera.scale *= 2
		; to reset the vertical zoom
		"scalereset": xlc_event_camera.scale = xlc_event_camera.original_scale

		; to zoom in (toward center), horizontally
		"zoom + ": begin
			; if xrange is not set, just zoom in
			xlc_event_camera.zoom *=0.5
			; if xrange is set to something custom, manually readjust it
			if  xlc_event_camera.xrange[0] ne 0 or xlc_event_camera.xrange[1] ne 0 then begin
				center = mean(xlc_event_camera.xrange)
				span = max(xlc_event_camera.xrange)- min(xlc_event_camera.xrange)
				xlc_event_camera.xrange = center + [-1.,1.]*span/2.0*0.5
			endif
		end
		; to zoom out (from center), horizontally
		"zoom - ": begin
			; if xrange is not set, just zoom out
			xlc_event_camera.zoom *=2
			; if xrange is set to something custom, manually readjust it
			if  xlc_event_camera.xrange[0] ne 0 or xlc_event_camera.xrange[1] ne 0 then begin
				center = mean(xlc_event_camera.xrange)
				span = max(xlc_event_camera.xrange)- min(xlc_event_camera.xrange)
				xlc_event_camera.xrange = center + [-1.d,1.d]*span/2.0d*2.0d
			endif
		end
		; to reset the horizontal zoom to the default
		"zoomreset": begin
			xlc_event_camera.zoom = 1.0
			xlc_event_camera.xrange = [0,0]
		end
		; to use the mouse to select the zoom range (can also click on the plot with middle mouse buttons)
		"zoomcustom": 	begin
			widget_control, xlc_event_camera.message_label_id, set_val='Please pick the LEFT side of your zoom range.'
			xlc_event_camera.setting_zoom_left = 1
		end
		; to input a specific MJD and go to that spot
		"mjd":begin
			widget_control, xlc_event_camera.mjdbox_id, get_value=userinputmjd
			center = double(userinputmjd[0])
			xlc_event_camera.xrange = center+ [-0.5d, 0.5d] + 2400000.5d
			widget_control, xlc_event_camera.mjdbox_id, set_value=''

		end
		; to input a specific "night" in YYYYMMDD format and go to that spot
		"night":begin
			widget_control, xlc_event_camera.nightbox_id, get_value=userinputnight
			if userinputnight[0] lt 20500000L and userinputnight[0] gt 19500000L then begin
				center = hopkinsnighttomjd(userinputnight[0])
				xlc_event_camera.xrange = center+ [-0.5d, 0.5d] + 2400000.5d
			endif
			widget_control, xlc_event_camera.nightbox_id, set_value=''
		end
		; toggle plotting options on or off
		"optionbinned" : xlc_event_camera.binned = ~xlc_event_camera.binned
		"optionmodel" : xlc_event_camera.model = ~xlc_event_camera.model
		"optionraw" : xlc_event_camera.raw = ~xlc_event_camera.raw
		"optionoutliers" : xlc_event_camera.outliers = ~xlc_event_camera.outliers
		"optionin-transit" : xlc_event_camera.intransit = ~xlc_event_camera.intransit
		"optionhistograms" : xlc_event_camera.histograms = ~xlc_event_camera.histograms
		"optiondiagnostics" : begin
			xlc_event_camera.diagnostics = ~xlc_event_camera.diagnostics
			if xlc_event_camera.diagnostics then begin
				new_ysize = height*2 + xlc_event_camera.ypad
			endif else begin
				new_ysize = height + xlc_event_camera.ypad
			endelse
			resized = 1
		end
		"optionanonymous?" : xlc_event_camera.anonymous = ~xlc_event_camera.anonymous
		; "optioncomparisons" : xlc_event_camera.comparisons = ~xlc_event_camera.comparisons

		; should we plot the variability light curve?
		"whichlcvariability" : xlc_event_camera.variability = ~xlc_event_camera.variability
		; should we plot the cleaned light curve
		"whichlccleaned" : xlc_event_camera.cleaned = ~xlc_event_camera.cleaned

		; to save the current plot to eps
		"eps" : begin
			widget_control, xlc_event_camera.message_label_id, set_val='Saving to EPS; acroread will open shortly.'
			xlc_event_camera.eps=1
		end
		; to save the current plot to png
		"png" : begin
			widget_control, xlc_event_camera.message_label_id, set_val='Saving to PNG; konqueror will open shortly.'
			xlc_event_camera.png=1
		end
		; to save the light curves to an ascii file
		"ascii": savetoascii
		; to comment on the star, to mark it as KNOWN, ???, ???
		"comment": comment_in_log


		; to use the mouse to select the zoom range (can also click on the plot with middle mouse buttons)
		"select": begin
			widget_control, xlc_event_camera.message_label_id, set_val='Click to the LOWER LEFT of points to select.'
			xlc_event_camera.setting_select_left = 1
		end
		"unselect": begin
			xlc_event_camera.setting_select_left = 0
			xlc_event_camera.setting_select_right = 0
			xlc_event_camera.select_xrange = [0,0]
			xlc_event_camera.select_yrange = [0,0]
		end
		'ds9':begin
			ds9_some_hjds, xlc_event_selected_times.raw, xpa_name=xpa_name,  filenames=filenames, pid=pid
			xlc_event_ds9 = {xpa_name:xpa_name, filenames:filenames, hjds:xlc_event_selected_times.raw, pid:pid};, flagged:bytarr(n_elements(xlc_event_selected_times.raw))}
			print, xpa_name
		end
		'flag image':begin
			if n_tags(xlc_event_ds9) gt 0 then begin
				flag_ds9, xpa_name=xlc_event_ds9.xpa_name, image_filenames=xlc_event_ds9.filenames, image_hjds=xlc_event_ds9.hjds, censored_exposures=xlc_event_censored_exposures, censored_filenames=xlc_event_censored_filenames
			endif
		end
		'censor': begin
			xlc_event_camera.perform_censoring = 1
		end
		'test_cm': begin
			test_cm, event= xlc_event_camera.events[xlc_event_camera.whichevent], /eps
		end
		'save':begin
			n_flagged_in_ds9 =  n_elements(xlc_event_censored_exposures)
			if n_flagged_in_ds9 gt 0 then begin
				openw, raw_censor_lun, /get_lun, star_dir + 'raw_image_xlc_event_censorship.log', /append
				for i=0, n_flagged_in_ds9-1 do begin
					if total(xlc_event_censored_exposures eq xlc_event_censored_exposures[i]) mod 2 ne 0 then begin
						printf, raw_censor_lun, string(format='(D13.7)', xlc_event_censored_exposures[i]) + ' = ' + xlc_event_censored_filenames[i] + ' was censored by '+username+' with ds9 on ' + systime()
					endif
				endfor
				close, raw_censor_lun
				spawn, 'kwrite ' + star_dir + 'raw_image_xlc_event_censorship.log'
				spawn, 'touch ' + star_dir + 'needtomakemarple'
			endif
			if n_tags(xlc_event_ds9) gt 0 then begin
				; quit the ds9 window you were using
				spawn, 'xpaset -p '+ xlc_event_ds9.xpa_name +' quit;'
			endif
			if n_tags(xlc_event_censorship) gt 0 then begin
				if total(xlc_event_censorship.okay, /int) ne n_elements(xlc_event_censorship) then begin
					openw, censor_lun, /get_lun, star_dir + 'xlc_event_censorship.log', /append
					i_censor=where(xlc_event_censorship.okay eq 0, n_censor)
					for i=0, n_censor-1 do printf, censor_lun, string(format='(D13.7)', xlc_event_censorship[i_censor[i]].hjd) + ' was censored by hand by '+username+' on ' + systime()
					close, censor_lun
					spawn, 'kwrite ' + star_dir + 'xlc_event_censorship.log'
					spawn, 'touch ' + star_dir + 'needtomakemarple'
				endif
			endif
			WIDGET_CONTROL, event.top, /DESTROY
			return
		end
		'dontsave': begin
			WIDGET_CONTROL, event.top, /DESTROY
			if n_tags(xlc_event_ds9) gt 0 then begin
				; quit the ds9 window you were using
				spawn, 'xpaset -p '+ xlc_event_ds9.xpa_name +' quit;'
			endif
			return
		end
		else: print, "there's no event handler defined for ", thebuttonclicked
	ENDCASE

;
	if tag_names(event, /struc) eq "WIDGET_BASE" then resized = 1;thebuttonclicked = "resized"
	if keyword_set(resized) then begin

		; was the window resized manually?
		if tag_names(event, /struc) eq "WIDGET_BASE" then begin
			new_xsize = event.x
			new_ysize = event.y
		; or was it resized within the program
		endif else begin
			; new_xsize and new_ysize
		endelse

		; set the new size of the window
		widget_control, xlc_event_camera.base_id, xsize=new_xsize, ysize=new_ysize

		; figure out how big the window is
		frame_info =  widget_info(xlc_event_camera.base_id, /geom)
		frame_height = frame_info.ysize
		frame_width = frame_info.xsize
		draw_width = frame_width - xlc_event_camera.xpad
		draw_height = frame_height -  xlc_event_camera.ypad;(topborder + bottomborder )

		; resize the draw window
		widget_control, xlc_event_camera.draw_id, xsize=long(draw_width), YSIZE =long(draw_height)
		wset, xlc_event_camera.draw_window
		erase
		print, 'draw'
;		help, widget_info(xlc_event_camera.draw_id, /geom)
		printl
	endif

;	debugging
;	print_struct, event
;	print_struct, xlc_event_camera
;	print, 'xrange is ', xlc_event_camera.xrange

	needtoplot=1B
	while (needtoplot $
		and xlc_event_camera.setting_zoom_left eq 0 and xlc_event_camera.setting_zoom_right eq 0$
		and xlc_event_camera.setting_select_left eq 0 and xlc_event_camera.setting_select_right eq 0) do begin
		set_plot, 'x'
		wset, xlc_event_camera.draw_window
		device, decomposed=0
		cleanplot, /silent
		loadct, 0
		!p.background=255
		!p.color=0
		plot, [0], /nodata, xs=4, ys=4
		coordinate_conversions = 0

		if xlc_event_camera.xrange[0] ne 0 or xlc_event_camera.xrange[1] ne 0 then xrange=xlc_event_camera.xrange else xrange=0
		lc_plot, /event, box = xlc_event_camera.events[xlc_event_camera.whichevent], zoom=xlc_event_camera.zoom, shift=xlc_event_camera.shift, scale=xlc_event_camera.scale, /externalformat, charsize=1, symsize=xlc_event_camera.symsize, /time,binned=xlc_event_camera.binned, anonymous=xlc_event_camera.anonymous, no_model=~keyword_set(xlc_event_camera.model), no_cleaned=~keyword_set(xlc_event_camera.cleaned), no_var=~keyword_set(xlc_event_camera.variability), no_raw=~keyword_set(xlc_event_camera.raw), no_outliers=~keyword_set(xlc_event_camera.outliers), noright=~keyword_set(xlc_event_camera.histograms), no_intransit=~keyword_set(xlc_event_camera.intransit), eps=keyword_set(xlc_event_camera.eps), png=keyword_set(xlc_event_camera.png), diagnos=xlc_event_camera.diagnostics, compa=xlc_event_camera.comparisons, coordinate_conversions=coordinate_conversions, xrange=xrange, select_xrange=xlc_event_camera.select_xrange, select_yrange=xlc_event_camera.select_yrange , select_which= xlc_event_camera.select_which, selected_times = xlc_event_selected_times, censorship=xlc_event_censorship, perform_censoring=xlc_event_camera.perform_censoring

		xlc_event_camera.perform_censoring = 0
		needtoplot =0B
		xlc_event_coordinate_conversions = coordinate_conversions

		if keyword_set(xlc_event_camera.eps) or keyword_set(xlc_event_camera.png) then begin
			xlc_event_camera.eps = 0
			xlc_event_camera.png = 0
			needtoplot = 1B
		endif
	endwhile

	; update the selections
;	help, xlc_event_selected_times
	if n_tags(xlc_event_selected_times) gt 0 then begin
		widget_control, xlc_event_camera.select_label_id, set_value=rw(xlc_event_selected_times.n_raw) + ' exp. + ' + rw(xlc_event_selected_times.n_binned) + ' obs.'+ 'selected'
		widget_control, xlc_event_camera.ds9_button_id, sensitive=xlc_event_selected_times.n_raw gt 0 or xlc_event_selected_times.n_binned gt 0
		widget_control, xlc_event_camera.flag_ds9_button_id, sensitive=xlc_event_selected_times.n_raw gt 0 or xlc_event_selected_times.n_binned gt 0
		widget_control, xlc_event_camera.censor_button_id, sensitive=xlc_event_selected_times.n_raw gt 0 or xlc_event_selected_times.n_binned gt 0
	endif else begin
		widget_control, xlc_event_camera.ds9_button_id, sensitive=0
		widget_control, xlc_event_camera.flag_ds9_button_id, sensitive=0
		widget_control, xlc_event_camera.censor_button_id, sensitive=0
	endelse

END



;------------------------------------------------------------------------------
;	procedure xlc_event
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the xlc_event widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the
;*** currently active widgets.
;------------------------------------------------------------------------------
PRO xlc_event, GROUP = GROUP, BLOCK=block, id=id

	common xlc_event_common

	;*** If xlc_event can have multiple copies running, then delete the following
	;*** line and the comment for it.  Often a common block is used that prohibits
	;*** multiple copies of the widget application from running.  In this case,
	;*** leave the following line intact.

	; only run one xlc_event widget at a tiem
	IF(XRegistered("xlc_event") NE 0) THEN begin
	RETURN
	endif
	IF N_ELEMENTS(block) EQ 0 THEN block=0

	; get the widget geometry from the definition file
	@widget_geometries

	; make the main xlc_event window
	xlc_eventbase = WIDGET_BASE(TITLE = "xlc_event", row=3,/base_align_center, /tlb_size_events);

	; define the window's ID so it can be killed externally
	id = xlc_eventbase

	; set up three rows for widget base
	toprow_base =  WIDGET_BASE(xlc_eventbase, /row, /base_align_center, frame=3);xoffset=leftborder/2,
		output_buttons_base = widget_base(toprow_base, /row, /align_center)
		messagebox_base = widget_base(toprow_base, /row, /align_center)
	supermiddlerow_base =  WIDGET_BASE(xlc_eventbase, /base_align_center, /row, frame=3)
		left_base = widget_base(supermiddlerow_base, /base_align_center)
		middlerow_base =  WIDGET_BASE(supermiddlerow_base, /base_align_center, col=3, frame=3)
		right_base = widget_base(supermiddlerow_base, /base_align_center)
	bottomrow_base =  WIDGET_BASE(xlc_eventbase, /row, /base_align_center, frame=3);xoffset=0, ysize=bottomborder,yoffset=topborder + height,
		outer_goto_base = widget_base(bottomrow_base, /col, /base_align_center, frame=2)
			mjdbox_label = widget_label(outer_goto_base, value='Jump to a Moment:')
			goto_base = widget_base(outer_goto_base, /row, /base_align_center)
		xrange_base = WIDGET_BASE(bottomrow_base, /row, /base_align_center, frame=0)
		select_base = widget_base(bottomrow_base, /col, /base_align_center, frame=2)
			topselect_base = widget_base(select_base, /row, /base_align_center)
			bottomselect_base = widget_base(select_base, /row, /base_align_center)
		extra_base = WIDGET_BASE(bottomrow_base, /row, /base_align_center, frame=0)

	; populate top row with buttons controlling output and a message window
	eps_button = widget_button(output_buttons_base, uvalue='eps', value='save to EPS', accelerator='Shift+E')
	png_button = widget_button(output_buttons_base, uvalue='png', value='save to PNG', accelerator='Shift+P')
	ascii_button = widget_button(output_buttons_base, uvalue='ascii', value='save to ASCII', accelerator='Shift+A')
	comment_button = widget_button(output_buttons_base, uvalue='comment', value='comment on star', accelerator='Shift+C')

	message_label = widget_label(messagebox_base, uvalue='message', value='                                                           ', frame=1)
	dontsave_button = widget_button(output_buttons_base, uvalue='dontsave', value='quit+undo', accelerator='Shift+Q')
	save_button = widget_button(output_buttons_base, uvalue='save', value='QUIT+SAVE', accelerator='Shift+S')




	; populate options on the left panel
	whichlc_values = ['basic', 'variability', 'cleaned']
	whichlc_set_value = [1, 1, 1]
	whichlc_buttons = cw_bgroup(middlerow_base, whichlc_values, /COLUMN, LABEL_TOP='Light curves:', frame=3,uvalue='whichlc'+whichlc_values, /nonexclus, set_value=whichlc_set_value)

	option_values = ['binned', 'model', 'raw', 'outliers', 'in-transit', 'histograms', 'diagnostics','anonymous?']; 'comparisons',
	options_set_value = [0, 1, 0, 1, 0, 1, 0]
	option_buttons = cw_bgroup(middlerow_base, option_values, /COLUMN, LABEL_TOP='Options:', frame=3,uvalue='option'+option_values, /nonexclus, set_value=options_set_value)

	; create the draw window
	draw = WIDGET_DRAW(middlerow_base, XSIZE = width, YSIZE =height, units=0, fram=5, uval='draw', /button_event)

	; create flux zoom buttons
	scale_values = [' + ',  ' - ', 'reset']
	scale_buttons = cw_bgroup(middlerow_base, scale_values, /COLUMN, LABEL_TOP='Flux Zoom:', frame=0, uvalue='scale'+scale_values)

	; create time zoom buttons
	zoom_values = [' + ', ' - ', 'custom', 'reset']
	zoom_buttons = cw_bgroup(xrange_base, zoom_values, /row, LABEL_TOP='Time Zoom:', uvalue='zoom'+zoom_values, frame=2)

	; create goto
	mjdbox_label = widget_label(goto_base, value='MJD:')
	mjdbox_text = widget_text(goto_base, uvalue='mjd', xsize=10, /edit)

	; create goto
	nightbox_label = widget_label(goto_base, value='YYYYMMDD:')
	nightbox_text = widget_text(goto_base, uvalue='night', xsize=10, /edit)




	;create select buttons
	leftselect_base =  widget_base(/col, topselect_base)
	select_button =widget_button( leftselect_base, uvalue='select', value='select')
	unselect_button =widget_button( leftselect_base, uvalue='unselect', value='unselect')
	select_label = widget_label(leftselect_base, value='                    0 selected')
	dosomething_base =  widget_base(/col, topselect_base)
		ds9_button = widget_button(dosomething_base, uvalue='ds9', value='ds9 selected', sensitive=0)
		flag_ds9_button = widget_button(dosomething_base, uvalue='flag image', value='flag ds9 image', sensitive=0)
		censor_button = widget_button(dosomething_base, uvalue='censor', value='censor points', sensitive=0)
;	context_button = widget_button(bottomselect_base, uvalue='context', value='see in context', sensitive=0)

	test_cm_button = widget_button(extra_base, uvalue='test_cm', value='Look at CM?')

;===============

	restore, star_dir() + 'cleaned_lc.idl'
	restore, star_dir() + 'box_pdf.idl'
	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)

	phased_time = (boxes.hjd - candidate.hjd0)/candidate.period mod 1.0
	i_under = where(phased_time lt -0.5, n_under)
	if n_under gt 0 then phased_time[i_under] +=1
	i_over = where(phased_time gt 0.5, n_over)
	if n_over gt 0 then phased_time[i_over] -=1
	phased_time *= candidate.period
	mingap = min(boxes[1:*].hjd - boxes.hjd)
	i_boxesintransit = where(abs(phased_time) lt mingap/2.0, n_it)
	sorted = reverse(sort(boxes[i_boxesintransit].depth[i_duration]/boxes[i_boxesintransit].depth_uncertainty[i_duration]))
	whichevent = sorted[0]

	; populat previous and next event buttons
	previous_button = widget_button(left_base, uvalue='previous', value ='previous event', sensitive=whichevent ne 0)
	next_button = widget_button(right_base, uvalue='next', value='next event', sensitive=whichevent ne n_it-1)

	; is the a kludge?
	if n_it eq 0 then return


	events = replicate({hjd:0.0d, depth:0.0d, depth_uncertainty:0.0d, duration:0.0}, n_it)
	events.hjd = boxes[i_boxesintransit].hjd
	events.depth = boxes[i_boxesintransit].depth[i_duration]
	events.depth_uncertainty = boxes[i_boxesintransit].depth_uncertainty[i_duration]
	events.duration = boxes[i_boxesintransit].duration[i_duration]




	; bring the whole thing into existence
	WIDGET_CONTROL, xlc_eventbase, /REALIZE

	; figure out what window index correponds to the draw window
	WIDGET_CONTROL, draw, GET_VALUE = draw_window

	; first pass at plot
	WSET, draw_window
	cleanplot, /silent
	loadct, 0
	!p.background=255
	!p.color=0
	plot, [0], /nodata, xs=4, ys=4
	lc_plot, /event, box=events[whichevent], zoom=zoom, shift=shift, scale=scale, /externalformat, charsize=1, symsize=0.6, /time, binned=0, /no_raw, /no_int, coordinate_conversions=coordinate_conversions, failed=failed
	if keyword_set(failed) then return
	if n_elements(coordinate_conversions) gt 0 then xlc_event_coordinate_conversions = coordinate_conversions



	; define a structure that contains variables needed to keep track of options
	xlc_event_camera = {candidate:candidate, events:events, whichevent:whichevent, $
				next_id:next_button, previous_id:previous_button, $
				zoom:zoom, shift:shift, scale:scale, xrange:[0.d,0.d], $
						xpad:0, ypad:0, $
						binned:0, model:1, raw:0, outliers:1, intransit:0, histograms:1, diagnostics:0, comparisons:0, anonymous:0, eps:0, png:0, $
						basic:1, variability:1, cleaned:1, $
						symsize:0.8,  original_scale:scale, $
						base_id:id, middlerow_id:middlerow_base, bottomrow_id:bottomrow_base, draw_id:draw, message_label_id:message_label, select_label_id:select_label,  ds9_button_id:ds9_button, flag_ds9_button_id:flag_ds9_button, censor_button_id:censor_button, mjdbox_id:mjdbox_text, nightbox_id:nightbox_text, $
						setting_zoom_left:0, setting_zoom_right:0,$
						setting_select_left:0, setting_select_right:0, select_xrange:[0.0d, 0.0d], select_yrange:[0.0d, 0.0d], select_which:0, $
						perform_censoring:0, $
						draw_window:draw_window}

	junk = temporary(xlc_event_select)
	junk = temporary(xlc_event_selected_times)
junk = temporary(xlc_event_ds9)
junk = temporary(xlc_event_censored_exposures)
junk = temporary( xlc_event_censored_filenames)
junk = temporary( xlc_event_censorship)
	xlc_event_censorship = 0

	frame_info =  widget_info(xlc_event_camera.base_id, /geom)
	xlc_event_camera.xpad = frame_info.xsize - width
	xlc_event_camera.ypad = frame_info.ysize - height

	; register the widget with the xmanager
	XManager, "xlc_event", xlc_eventbase, $
			EVENT_HANDLER = "xlc_event_ev", $
			GROUP_LEADER = GROUP, $
			NO_BLOCK=(NOT(FLOAT(block)))


END
