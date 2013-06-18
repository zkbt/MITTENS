;+
; NAME:
;	xlc_plot
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual 
;	implementation of the xlc_plot widget.  Use a global search and 
;	replace to replace the word "xlc_plot" with the name of the routine 
;	you would like to use. 
;
;	All the comments with a "***" in front of them should be read, decided 
;	upon and removed for your final copy of the xlc_plot widget
;	routine.
;
; CATEGORY:
;	Widgets.
;
; CALLING SEQUENCE:
;	xlc_plot
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls xlc_plot.  When this
;		ID is specified, the death of the caller results in the death
;		of xlc_plot.
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
;	procedure xlc_plot_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the xlc_plot widget.  It is 
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the xlc_plot widget.  The tool menu choice routines are 
;*** already installed.  This routine is required for the xlc_plot widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------
PRO xlc_plot_ev, event

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

  "orb. phase":	widget_lc_plot, xpos=xpos, ypos=ypos, /time, /phased, eps=eps, anonymous=anonymous
			;XLoadct is the library
							;routine that lets you
							;select and adjust the
							;color palette being
							;used.

  "XPalette": XPalette, GROUP = event.top		;XPalette is the
							;library routine that
							;lets you adjust 
							;individual color
							;values in the palette.

  "XManagerTool": XMTool, GROUP = event.top		;XManTool is a library
							;routine that shows 
							;which widget
							;applications are 
							;currently registered
							;with the XManager as
							;well as which
							;background tasks.

  "Done": WIDGET_CONTROL, event.top, /DESTROY		;There is no need to
							;"unregister" a widget
							;application.  The
							;XManager will clean
							;the dead widget from
							;its list.

  ELSE: print, "no event handler yet!"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE

END ;============= end of xlc_plot event handling routine task =============



;------------------------------------------------------------------------------
;	procedure xlc_plot
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the xlc_plot widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the 
;*** currently active widgets.  
;------------------------------------------------------------------------------
PRO xlc_plot, GROUP = GROUP, BLOCK=block

;*** If xlc_plot can have multiple copies running, then delete the following
;*** line and the comment for it.  Often a common block is used that prohibits
;*** multiple copies of the widget application from running.  In this case, 
;*** leave the following line intact.

;IF(XRegistered("xlc_plot") NE 0) THEN RETURN		;only one instance of
							;the xlc_plot widget
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
rightborder = 60
leftborder = 50
xlc_plotbase = WIDGET_BASE(TITLE = "xlc_plot", xsize=width + rightborder + leftborder, ysize=height + topborder + bottomborder)	;create the main base

;*** Here some default controls are built in a menu.  The descriptions of these
;*** procedures can be found in the xlc_plot_ev routine above.  If you would
;*** like to add other routines or remove any of these, remove them both below
;*** and in the xlc_plot_ev routine.

toprow =  WIDGET_BASE(xlc_plotbase, /row, xoffset=leftborder)
middlerow =  WIDGET_BASE(xlc_plotbase, col=2, ysize=height,xoffset=leftborder, yoffset=topborder)
bottomrow =  WIDGET_BASE(xlc_plotbase, /row,  ysize=bottomborder,xoffset=leftborder, yoffset=topborder + height)

eps = widget_button(toprow, uvalue='eps', value='save to EPS')
png = widget_button(toprow, uvalue='png', value='save to PNG')

;WIDGET_CONTROL, xlc_plotbase, /REALIZE			;create the widgets

; geo = widget_info(xlc_plotbase, /geometry)


draw = WIDGET_DRAW(middlerow, XSIZE = width, YSIZE =height, units=0, fram=0) 
;draw = WIDGET_DRAW(middlerow, XSIZE = geo.xsize -100, YSIZE = geo.ysize-100) 
;zoomscale = widget_base(middlerow, /col)

; scaletext = widget_text(zoomscale, value='Zoom Flux')
; scalein = widget_button(zoomscale, uvalue='scalein', value='IN')
; scaleout = widget_button(zoomscale, uvalue='scalein', value='OUT')

scale_values = ['in', 'out']
scale_buttons = cw_bgroup(middlerow, scale_values, /COLUMN, LABEL_TOP='Flux:', /FRAME, uvalue='scale'+scale_values, xoffset=left)

zoom_values = ['in', 'out']
zoom_buttons = cw_bgroup(bottomrow, zoom_values, /row, LABEL_TOP='Time:', /FRAME, uvalue='zoom'+zoom_values)



;scaleslider = widget_slider(middlerow, title='Zoom in Flux', min=1, max=100, value=50, uval='scale',  /suppress_value, /vertical, ysize=200)     ; slider 

;zoomslider = widget_slider(bottomrow, title='Zoom in Time', min=1, max=100, value=50,  uval='zoom', /suppress_value, xsize=200)     ; slider 

; zoomin = widget_button(bottomrow, uvalue='scalein', value='IN')
; zoomout = widget_button(bottomrow, uvalue='scalein', value='OUT')


 


;*** Typically, any widgets you need for your application are created here.
;*** Create them and use xlc_plotbase as their base.  They will be realized
;*** (brought into existence) when the following line is executed.

WIDGET_CONTROL, xlc_plotbase, /REALIZE			;create the widgets
							;that are defined

; ;Obtain the window index. 
 WIDGET_CONTROL, draw, GET_VALUE = index 
;  
; ;Set the new widget to be the current graphics window 
WSET, index 
cleanplot
loadct, 0
!p.background=255
!p.color=0
plot, [0], /nodata, xs=4, ys=4
lc_plot, _extra=_extra, zoom=zoom, shift=shift, scale=scale, /externalformat, charsize=1, symsize=1




XManager, "xlc_plot", xlc_plotbase, $			;register the widgets
		EVENT_HANDLER = "xlc_plot_ev", $	;with the XManager
		GROUP_LEADER = GROUP, $			;and pass through the
		NO_BLOCK=(NOT(FLOAT(block)))		;group leader if this
							;routine is to be 
							;called from some group
							;leader.

END ;==================== end of xlc_plot main routine =======================
