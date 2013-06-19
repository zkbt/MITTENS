;+
; NAME:
;	xinspect
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual 
;	implementation of the xinspect widget.  Use a global search and 
;	replace to replace the word "xinspect" with the name of the routine 
;	you would like to use. 
;
;	All the comments with a "***" in front of them should be read, decided 
;	upon and removed for your final copy of the xinspect widget
;	routine.
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

PRO zkb_kill_widget, widget_name
stop
END
;------------------------------------------------------------------------------
;	procedure xinspect_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the xinspect widget.  It is 
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the xinspect widget.  The tool menu choice routines are 
;*** already installed.  This routine is required for the xinspect widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------
PRO xinspect_ev, event
common xinspect_common, child_ids
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

  "orb. phase":	begin
				if event.select eq 1 then begin
					xlc_orbit, id=xlc_orbitbase, group=child_ids.xinspect
					child_ids.xlc_orbit = xlc_orbitbase
				endif
				if event.select eq 0 then begin
					if widget_info(child_ids.xlc_orbit, /valid) then  widget_control, child_ids.xlc_orbit, /destroy
				endif
			end

  "time":	begin
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

  ELSE: print, "no event handler yet!"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE


END ;============= end of xinspect event handling routine task =============



;------------------------------------------------------------------------------
;	procedure xinspect
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the xinspect widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the 
;*** currently active widgets.  
;------------------------------------------------------------------------------
PRO xinspect, GROUP = GROUP, BLOCK=block
common xinspect_common

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

outputs = widget_base(xinspectbase, row=1, /frame)
eps = widget_button(outputs, uvalue='eps', value='save to EPS')
png = widget_button(outputs, uvalue='png', value='save to PNG')
blog = widget_button(outputs, uvalue='blog', value='post to blog')

thingstoplot = widget_base(xinspectbase, row=2, /frame, /nonexclusive)
thingstoplot_values = ['event', 'orb. phase', 'rot. phase', 'time', '#', 'D/sigma', 'correlations', 'periodogram', 'MarPLE']
thingstoplot_setvalues = [0,1,0,0,0,0,0,0,0]
thingstoplot = cw_bgroup(xinspectbase, thingstoplot_values, /COLUMN, /NONEXCLUSIVE, LABEL_TOP='Plots to Show', /FRAME, uvalue=thingstoplot_values, uname='thingstoplot', set_val=thingstoplot_setvalues)



; opends9 = widget_base(xinspectbase, /column)
; imagepernight = widget_button(opends9, uvalue='ds9 [1 image]/night', value='ds9 [1 image]/night')
; imagesintransit = widget_button(opends9, uvalue='ds9 in-transit images', value='ds9 in-transit images')
; imagesneartransit = widget_button(opends9, uvalue='ds9 near-transit images', value='ds9 near-transit images')


opends9_values = ['[1 image]/night', 'in-transit', 'near-transit']
opends9 = cw_bgroup(xinspectbase, opends9_values, /COLUMN, LABEL_TOP='Open Images in ds9?', /FRAME, uvalue=opends9_values)

done = WIDGET_BUTTON(xinspectbase, value='Done', uvalue='Done') 

;draw = WIDGET_DRAW(xinspectbase, XSIZE = 256, YSIZE = 256) 
 
xinspect_variables = {xinspectbase:xinspectbase}


;*** Typically, any widgets you need for your application are created here.
;*** Create them and use xinspectbase as their base.  They will be realized
;*** (brought into existence) when the following line is executed.

WIDGET_CONTROL, xinspectbase, /REALIZE			;create the widgets
							;that are defined

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

if thingstoplot_setvalues[1] then begin
	xlc_orbit, id=xlc_orbitbase, group=child_ids.xinspect
	child_ids.xlc_orbit = xlc_orbitbase
endif
if thingstoplot_setvalues[2] then begin
	xlc_rotation, id=xlc_rotationbase, group=child_ids.xinspect
	child_ids.xlc_rotation = xlc_rotationbase
endif
if thingstoplot_setvalues[3] then begin
	xlc_time, id=xlc_timebase, group=child_ids.xinspect
	child_ids.xlc_time = xlc_timebase
endif

END ;==================== end of xinspect main routine =======================
