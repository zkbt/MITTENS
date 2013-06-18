;+
; NAME:
;	xlc_orbit
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual 
;	implementation of the xlc_orbit widget.  Use a global search and 
;	replace to replace the word "xlc_orbit" with the name of the routine 
;	you would like to use. 
;
;	All the comments with a "***" in front of them should be read, decided 
;	upon and removed for your final copy of the xlc_orbit widget
;	routine.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	xlc_orbit
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls xlc_orbit.  When this
;		ID is specified, the death of the caller results in the death
;		of xlc_orbit.
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
;	procedure xlc_orbit_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the xlc_orbit widget.  It is 
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the xlc_orbit widget.  The tool menu choice routines are 
;*** already installed.  This routine is required for the xlc_orbit widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------

FUNCTION smulti_datacoord, event=event, coordinate_converstions=coordinate_conversions, geometry=geometry
	; event must be a draw event
	; coordinate conversions must at least contain x, y, p tags
	pixel_click = {x:event.x, y:event.y}
	for i=0, n_elements(coordinate_conversions)-1 do begin
		normal_position = coordinate_conversions[i].p.position
		pixel_xrange = [normal_position[0], normal_position[2]]*geometry.xsize
		pixel_yrange = [normal_position[1], normal_position[3]]*geometry.ysize
		in_this_plot = pixel_click.x ge pixel_xrange[0] and pixel_click.x le pixel_xrange[1] and pixel_click.y ge pixel_yrange[0] and pixel_click.y le pixel_yrange[1] 
		if in_this_plot then begin
			!x = coordinate_conversions[i].x
			!y = coordinate_conversions[i].y
			!p = coordinate_conversions[i].p
			click = convert_coord(pixel_click.x, pixel_click.y, /device, /data)
			return, {x:click[0], y:click[1], which:i}
		endif else i_plot = -1
	endfor
; 	print, clicked_in_this_plot
; cleanplot          
; plot, pixel_xrange, pixel_yrange, /yno 
; plots, psym=1, symsize=5, pixel_click.x, pixel_click.y      
; plots, psym=1, symsize=5, pixel_click.x, pixel_click.y
; 
; 	if i
	; figure out which window it was in
END

PRO xlc_orbit_ev, event

common xlc_orbit_common, xlc_orbit_camera, xlc_orbit_coordinate_conversions

COMPILE_OPT hidden					; Don't appear in HELP
							; output unless HIDDEN
							; keyword is specified.

WIDGET_CONTROL, event.id, GET_UVALUE = eventval		;find the user value
							;of the widget where
print_struct, event
print, "eventval is : ", eventval							;the event occured
IF N_ELEMENTS(eventval) EQ 0 THEN RETURN

if n_elements(eventval) gt 1 then begin
	thebuttonclicked = eventval[event.value]
endif else thebuttonclicked = eventval

print, 'thebuttonclicked is ', thebuttonclicked

CASE thebuttonclicked OF

;*** here is where you would add the actions for your events.  Each widget
;*** you add should have a unique string for its user value.  Here you add
;*** a case for each of your widgets that return events and take the
;*** appropriate action.
  "draw": begin
			geometry = widget_info(event.id, /geom)
			data_click = smulti_datacoord(event=event, coordinate_converstions=xlc_orbit_coordinate_conversions, geometry=geometry)
			print, data_click
		
			if xlc_orbit_camera.setting_range_right then begin
				if event.press eq 1 then begin
					vline, data_click.x
					xlc_orbit_camera.xrange[1] = data_click.x
					widget_control, xlc_orbit_camera.messageid, set_val='Zooming in to ' + string(form='(F5.1)', xlc_orbit_camera.xrange[0]) + ' to ' + string(form='(F5.1)', xlc_orbit_camera.xrange[1])
				endif	
				if event.release eq 1 then begin
					xlc_orbit_camera.setting_range_right = 0
					widget_control, xlc_orbit_camera.messageid, set_val=''
				endif
			endif
	
			if xlc_orbit_camera.setting_range_left then begin
				if event.press eq 1 then begin
					vline, data_click.x
				endif
				if event.release eq 1 then begin
					widget_control, xlc_orbit_camera.messageid, set_val='Please pick the RIGHT side of your zoom range.'
					xlc_orbit_camera.setting_range_left = 0
					xlc_orbit_camera.setting_range_right = 1
					xlc_orbit_camera.xrange[0] = data_click.x
				endif
			endif
		end
  "scale + ": xlc_orbit_camera.scale *= 0.5
  "scale - ": xlc_orbit_camera.scale *= 2		
  "scalereset": xlc_orbit_camera.scale = xlc_orbit_camera.original_scale

  "zoom + ": 	begin
				xlc_orbit_camera.zoom *=0.5	
				if  xlc_orbit_camera.xrange[0] ne 0 or xlc_orbit_camera.xrange[1] ne 0 then begin
					center = mean(xlc_orbit_camera.xrange)
					span = max(xlc_orbit_camera.xrange)- min(xlc_orbit_camera.xrange)
					xlc_orbit_camera.xrange = center + [-1.,1.]*span/2.0*0.5
				endif
			end
 "zoom - ": 	begin
				xlc_orbit_camera.zoom *=2		
				if  xlc_orbit_camera.xrange[0] ne 0 or xlc_orbit_camera.xrange[1] ne 0 then begin
					center = mean(xlc_orbit_camera.xrange)
					span = max(xlc_orbit_camera.xrange)- min(xlc_orbit_camera.xrange)
					xlc_orbit_camera.xrange = center + [-1.,1.]*span/2.0*2.0

				endif
			end
  "zoomreset": begin
				xlc_orbit_camera.zoom = 1.0
				xlc_orbit_camera.xrange = [0,0]
			end
  "zoomselect": 	begin
					widget_control, xlc_orbit_camera.messageid, set_val='Please pick the LEFT side of your zoom range.'
					xlc_orbit_camera.setting_range_left = 1

				end
  "optionbinned" : xlc_orbit_camera.binned = ~xlc_orbit_camera.binned
  "optionmodel" : xlc_orbit_camera.model = ~xlc_orbit_camera.model
  "optionraw" : xlc_orbit_camera.raw = ~xlc_orbit_camera.raw
  "optionoutliers" : xlc_orbit_camera.outliers = ~xlc_orbit_camera.outliers
  "optionin-transit" : xlc_orbit_camera.intransit = ~xlc_orbit_camera.intransit
  "optionhistograms" : xlc_orbit_camera.histograms = ~xlc_orbit_camera.histograms
  "optiondiagnostics" : xlc_orbit_camera.diagnostics = ~xlc_orbit_camera.diagnostics
;  "optioncomparisons" : xlc_orbit_camera.comparisons = ~xlc_orbit_camera.comparisons
  "optionanonymous?" : xlc_orbit_camera.anonymous = ~xlc_orbit_camera.anonymous

  "whichlcvariability" : xlc_orbit_camera.variability = ~xlc_orbit_camera.variability
  "whichlccleaned" : xlc_orbit_camera.cleaned = ~xlc_orbit_camera.cleaned

  "eps" : xlc_orbit_camera.eps=1
	"png":xlc_orbit_camera.png = 1

  ELSE: print, "no event handler yet!"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE
print_struct, event
print_struct, xlc_orbit_camera


needtoplot=1B
while (needtoplot and xlc_orbit_camera.setting_range_left eq 0 and xlc_orbit_camera.setting_range_right eq 0) do begin
	set_plot, 'x'
	wset, xlc_orbit_camera.draw_id

	device, decomposed=0
	cleanplot, /silent
	loadct, 0
	!p.background=255
	!p.color=0
	plot, [0], /nodata, xs=4, ys=4
	coordinate_conversions = 0

	if xlc_orbit_camera.xrange[0] ne 0 or xlc_orbit_camera.xrange[1] ne 0 then xrange=xlc_orbit_camera.xrange else xrange=0
	lc_plot, zoom=xlc_orbit_camera.zoom, shift=xlc_orbit_camera.shift, scale=xlc_orbit_camera.scale, /externalformat, charsize=1, symsize=xlc_orbit_camera.symsize, /time, /phased, binned=xlc_orbit_camera.binned, anonymous=xlc_orbit_camera.anonymous, no_model=~keyword_set(xlc_orbit_camera.model), no_cleaned=~keyword_set(xlc_orbit_camera.cleaned), no_var=~keyword_set(xlc_orbit_camera.variability), no_raw=~keyword_set(xlc_orbit_camera.raw), no_outliers=~keyword_set(xlc_orbit_camera.outliers), noright=~keyword_set(xlc_orbit_camera.histograms), no_intransit=~keyword_set(xlc_orbit_camera.intransit), eps=keyword_set(xlc_orbit_camera.eps), png=keyword_set(xlc_orbit_camera.png), diagnos=xlc_orbit_camera.diagnostics, compa=xlc_orbit_camera.comparisons, coordinate_conversions=coordinate_conversions, xrange=xrange

	needtoplot =0B
	xlc_orbit_coordinate_conversions = coordinate_conversions
	
	if keyword_set(xlc_orbit_camera.eps) or keyword_set(xlc_orbit_camera.png) then begin
		xlc_orbit_camera.eps = 0
		xlc_orbit_camera.png = 0
		needtoplot = 1B
	endif
endwhile
END ;============= end of xlc_orbit event handling routine task =============



;------------------------------------------------------------------------------
;	procedure xlc_orbit
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the xlc_orbit widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the 
;*** currently active widgets.  
;------------------------------------------------------------------------------
PRO xlc_orbit, GROUP = GROUP, BLOCK=block, id=id

common xlc_orbit_common

;*** If xlc_orbit can have multiple copies running, then delete the following
;*** line and the comment for it.  Often a common block is used that prohibits
;*** multiple copies of the widget application from running.  In this case, 
;*** leave the following line intact.

IF(XRegistered("xlc_orbit") NE 0) THEN RETURN		;only one instance of
							;the xlc_orbit widget
							;is allowed.  If it is
							;already managed, do
							;nothing and return

IF N_ELEMENTS(block) EQ 0 THEN block=0

;*** Next the main base is created.  You will probably want to specify either
;*** a ROW or COLUMN base with keywords to arrange the widget visually.

width = 600
height = 400
topborder = 35
bottomborder = 70
rightborder = 100
leftborder = 130
xlc_orbitbase = WIDGET_BASE(TITLE = "xlc_orbit", xsize=width + rightborder + leftborder, ysize=height + topborder + bottomborder)	;create the main base

id = xlc_orbitbase
;*** Here some default controls are built in a menu.  The descriptions of these
;*** procedures can be found in the xlc_orbit_ev routine above.  If you would
;*** like to add other routines or remove any of these, remove them both below
;*** and in the xlc_orbit_ev routine.

toprow =  WIDGET_BASE(xlc_orbitbase, /row, xoffset=leftborder,/base_align_center)
middlerow =  WIDGET_BASE(xlc_orbitbase, col=3, ysize=height,xoffset=0, yoffset=topborder,/base_align_center)
bottomrow =  WIDGET_BASE(xlc_orbitbase, /column,  ysize=bottomborder,xoffset=leftborder, xsize=width,yoffset=topborder + height, /base_align_center)

eps = widget_button(toprow, uvalue='eps', value='save to EPS', accelerator='Shift+E')
png = widget_button(toprow, uvalue='png', value='save to PNG', accelerator='Shift+P')
message_box = widget_label(toprow, uvalue='message', value='                                                                                ', frame=1)

;WIDGET_CONTROL, xlc_orbitbase, /REALIZE			;create the widgets

; geo = widget_info(xlc_orbitbase, /geometry)

whichlc_values = ['basic', 'variability', 'cleaned']
whichlc_set_value = [1, 1, 1]
whichlc_buttons = cw_bgroup(middlerow, whichlc_values, /COLUMN, LABEL_TOP='Light curves:', frame=3,uvalue='whichlc'+whichlc_values, /nonexclus, set_value=whichlc_set_value)


option_values = ['binned', 'model', 'raw', 'outliers', 'in-transit', 'histograms', 'diagnostics','anonymous?']; 'comparisons', 
options_set_value = [0, 1, 0, 1, 0, 1, 0]
option_buttons = cw_bgroup(middlerow, option_values, /COLUMN, LABEL_TOP='Options:', frame=3,uvalue='option'+option_values, /nonexclus, set_value=options_set_value)


draw = WIDGET_DRAW(middlerow, XSIZE = width, YSIZE =height, units=0, fram=0, uval='draw', /button_event) 
;draw = WIDGET_DRAW(middlerow, XSIZE = geo.xsize -100, YSIZE = geo.ysize-100) 
;zoomscale = widget_base(middlerow, /col)

; scaletext = widget_text(zoomscale, value='Zoom Flux')
; scalein = widget_button(zoomscale, uvalue='scalein', value='IN')
; scaleout = widget_button(zoomscale, uvalue='scalein', value='OUT')

scale_values = [' + ',  ' - ', 'reset'];, 'select']
scale_buttons = cw_bgroup(middlerow, scale_values, /COLUMN, LABEL_TOP='Flux Zoom:', frame=0, uvalue='scale'+scale_values)

zoom_values = [' + ', ' - ', 'select', 'reset']
zoom_buttons = cw_bgroup(bottomrow, zoom_values, /row, LABEL_TOP='Time Zoom:', frame=0, uvalue='zoom'+zoom_values)


;scaleslider = widget_slider(middlerow, title='Zoom in Flux', min=1, max=100, value=50, uval='scale',  /suppress_value, /vertical, ysize=200)     ; slider 

;zoomslider = widget_slider(bottomrow, title='Zoom in Time', min=1, max=100, value=50,  uval='zoom', /suppress_value, xsize=200)     ; slider 

; zoomin = widget_button(bottomrow, uvalue='scalein', value='IN')
; zoomout = widget_button(bottomrow, uvalue='scalein', value='OUT')


 


;*** Typically, any widgets you need for your application are created here.
;*** Create them and use xlc_orbitbase as their base.  They will be realized
;*** (brought into existence) when the following line is executed.

WIDGET_CONTROL, xlc_orbitbase, /REALIZE			;create the widgets
							;that are defined

; ;Obtain the window index. 
 WIDGET_CONTROL, draw, GET_VALUE = index 
;  
; ;Set the new widget to be the current graphics window 
WSET, index 
cleanplot, /silent
loadct, 0
!p.background=255
!p.color=0
plot, [0], /nodata, xs=4, ys=4
lc_plot, zoom=zoom, shift=shift, scale=scale, /externalformat, charsize=1, symsize=0.6, /time, /phased, binned=0, /no_raw, /no_int, coordinate_conversions=coordinate_conversions
	xlc_orbit_coordinate_conversions = coordinate_conversions

xlc_orbit_camera = {zoom:zoom, shift:shift, scale:scale, binned:0, model:1, raw:0, outliers:1, intransit:0, histograms:1, diagnostics:0, comparisons:0, anonymous:0, eps:0, png:0, basic:1, variability:1, cleaned:1, symsize:0.6, original_scale:scale, drawid:draw, messageid:message_box, setting_range_left:0, setting_range_right:0, xrange:[0.,0.], draw_id:index}


XManager, "xlc_orbit", xlc_orbitbase, $			;register the widgets
		EVENT_HANDLER = "xlc_orbit_ev", $	;with the XManager
		GROUP_LEADER = GROUP, $			;and pass through the
		NO_BLOCK=(NOT(FLOAT(block)))		;group leader if this
							;routine is to be 
							;called from some group
							;leader.

END ;==================== end of xlc_orbit main routine =======================
