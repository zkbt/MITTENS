;+
; NAME:
;	xlc_time
;
; PURPOSE:
;	This routine is a template for widgets that use the XManager.  Use
;	this template instead of writing your widget applications from
;	"scratch".
;
;	This documentation should be altered to reflect the actual 
;	implementation of the xlc_time widget.  Use a global search and 
;	replace to replace the word "xlc_time" with the name of the routine 
;	you would like to use. 
;
;	All the comments with a "***" in front of them should be read, decided 
;	upon and removed for your final copy of the xlc_time widget
;	routine.
;
; CATEGORY:
;	Widgets.
; ;
; CALLING SEQUENCE:
;	xlc_time
;
; INPUTS:
;
; OPTIONAL INPUT PARAMETERS:
;
; KEYWORD PARAMETERS:
;	GROUP:	The widget ID of the widget that calls xlc_time.  When this
;		ID is specified, the death of the caller results in the death
;		of xlc_time.
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
;	procedure xlc_time_ev
;------------------------------------------------------------------------------
; This procedure processes the events being sent by the XManager.
;*** This is the event handling routine for the xlc_time widget.  It is 
;*** responsible for dealing with the widget events such as mouse clicks on
;*** buttons in the xlc_time widget.  The tool menu choice routines are 
;*** already installed.  This routine is required for the xlc_time widget to
;*** work properly with the XManager.
;------------------------------------------------------------------------------



PRO xlc_time_ev, event

common xlc_time_common, xlc_time_camera, xlc_time_coordinate_conversions, xlc_time_select
@widget_geometries

COMPILE_OPT hidden	; Don't appear in HELP output unless HIDDEN keyword is specified.
WIDGET_CONTROL, event.id, GET_UVALUE = eventval		;find the user value of the widget where the event occured

; debugging
print_struct, event


IF N_ELEMENTS(eventval) EQ 0 THEN thebuttonclicked = '' else begin
	print, "eventval is : ", eventval
	if n_elements(eventval) gt 1 then begin
		thebuttonclicked = eventval[event.value]
	endif else thebuttonclicked = eventval
endelse
;debugging
print, 'thebuttonclicked is ', thebuttonclicked

if tag_names(event, /struc) eq "WIDGET_BASE" then thebuttonclicked = "resized"
CASE thebuttonclicked OF
  "draw": begin
			geometry = widget_info(event.id, /geom)
			data_click = smulti_datacoord(event=event, coordinate_converstions=xlc_time_coordinate_conversions, geometry=geometry)
			print, data_click
		
			if xlc_time_camera.setting_range_right then begin
				if event.press eq 1 then begin
					vline, data_click.x, thick=4
					xlc_time_camera.xrange[1] = data_click.x
					widget_control, xlc_time_camera.message_label_id, set_val='Zooming in to ' + string(form='(F5.1)', xlc_time_camera.xrange[0]) + ' to ' + string(form='(F5.1)', xlc_time_camera.xrange[1])
				endif	
				if event.release eq 1 then begin
					xlc_time_camera.setting_range_right = 0
					widget_control, xlc_time_camera.message_label_id, set_val=''
				endif
			endif
	
			if xlc_time_camera.setting_range_left then begin
				if event.press eq 1 then begin
					vline, data_click.x, thick=4
					xbox = [!p.position[0], !p.position[2], !p.position[2],!p.position[0],!p.position[0]]
					ybox = [!p.position[1], !p.position[1], !p.position[3],!p.position[3],!p.position[1]]
					plots, /normal, xbox, ybox, thick=4
				endif
				if event.release eq 1 then begin
					widget_control, xlc_time_camera.message_label_id, set_val='Please pick the RIGHT side of your zoom range.'
					xlc_time_camera.setting_range_left = 0
					xlc_time_camera.setting_range_right = 1
					xlc_time_camera.xrange[0] = data_click.x
				endif
			endif
		end
  "scale + ": xlc_time_camera.scale *= 0.5
  "scale - ": xlc_time_camera.scale *= 2		
  "scalereset": xlc_time_camera.scale = xlc_time_camera.original_scale

  "zoom + ": 	begin
				xlc_time_camera.zoom *=0.5	
				if  xlc_time_camera.xrange[0] ne 0 or xlc_time_camera.xrange[1] ne 0 then begin
					center = mean(xlc_time_camera.xrange)
					span = max(xlc_time_camera.xrange)- min(xlc_time_camera.xrange)
					xlc_time_camera.xrange = center + [-1.,1.]*span/2.0*0.5
				endif
			end
 "zoom - ": 	begin
				xlc_time_camera.zoom *=2		
				if  xlc_time_camera.xrange[0] ne 0 or xlc_time_camera.xrange[1] ne 0 then begin
					center = mean(xlc_time_camera.xrange)
					span = max(xlc_time_camera.xrange)- min(xlc_time_camera.xrange)
					xlc_time_camera.xrange = center + [-1.d,1.d]*span/2.0d*2.0d

				endif
			end
  "zoomreset": begin
				xlc_time_camera.zoom = 1.0
				xlc_time_camera.xrange = [0,0]
			end
  "zoomcustom": 	begin
					widget_control, xlc_time_camera.message_label_id, set_val='Please pick the LEFT side of your zoom range.'
					xlc_time_camera.setting_range_left = 1

				end
  "optionbinned" : xlc_time_camera.binned = ~xlc_time_camera.binned
  "optionmodel" : xlc_time_camera.model = ~xlc_time_camera.model
  "optionraw" : xlc_time_camera.raw = ~xlc_time_camera.raw
  "optionoutliers" : xlc_time_camera.outliers = ~xlc_time_camera.outliers
  "optionin-transit" : xlc_time_camera.intransit = ~xlc_time_camera.intransit
  "optionhistograms" : xlc_time_camera.histograms = ~xlc_time_camera.histograms
  "optiondiagnostics" : begin
				xlc_time_camera.diagnostics = ~xlc_time_camera.diagnostics
				if xlc_time_camera.diagnostics then begin
					actual_height = height*2
				endif else begin
					actual_height = height
				endelse
				widget_control, xlc_time_camera.base_id, ysize=actual_height + topborder + bottomborder 
				widget_control, xlc_time_camera.bottomrow_id, yoffset=topborder + actual_height
				widget_control, xlc_time_camera.middlerow_id,  YSIZE =actual_height
					end

   "resized":begin
				widget_control, xlc_time_camera.base_id, xsize=event.x, ysize=event.y
				frame_info =  widget_info(xlc_time_camera.base_id, /geom)
				frame_height = frame_info.ysize
				frame_width = frame_info.xsize
				draw_height = frame_height - (topborder + bottomborder )
;WHY DOESN'T THE DRAW WINDOW RESIZE???
				widget_control, xlc_time_camera.bottomrow_id, yoffset=frame_height - bottomborder
				widget_control, xlc_time_camera.middlerow_id, YSIZE =draw_height

	print, 'base'
	widget_control, xlc_time_camera.draw_id, YSIZE =draw_height
	wset, xlc_time_camera.draw_window
	erase
	print, 'draw'
	help, widget_info(xlc_time_camera.draw_id, /geom)
	printl
		end

;  "optioncomparisons" : xlc_time_camera.comparisons = ~xlc_time_camera.comparisons
  "optionanonymous?" : xlc_time_camera.anonymous = ~xlc_time_camera.anonymous

  "whichlcvariability" : xlc_time_camera.variability = ~xlc_time_camera.variability
  "whichlccleaned" : xlc_time_camera.cleaned = ~xlc_time_camera.cleaned

  "eps" : begin
		widget_control, xlc_time_camera.message_label_id, set_val='Saving to EPS; acroread will open shortly.'
		xlc_time_camera.eps=1
		end
  "mjd":begin
		widget_control, xlc_time_camera.mjdbox_id, get_value=userinputmjd
		center = double(userinputmjd[0])
		xlc_time_camera.xrange = center+ [-0.5d, 0.5d] + 2400000.5d
		end
   "ascii": savetoascii

  ELSE: print, "no event handler yet!"		;When an event occurs
							;in a widget that has
							;no user value in this
							;case statement, an
							;error message is shown
ENDCASE

	

print_struct, event
print_struct, xlc_time_camera
print, 'xrange is ', xlc_time_camera.xrange

needtoplot=1B
while (needtoplot and xlc_time_camera.setting_range_left eq 0 and xlc_time_camera.setting_range_right eq 0) do begin
	set_plot, 'x'
	wset, xlc_time_camera.draw_window
	device, decomposed=0
	cleanplot, /silent
	loadct, 0
	!p.background=255
	!p.color=0
	plot, [0], /nodata, xs=4, ys=4
	coordinate_conversions = 0

	if xlc_time_camera.xrange[0] ne 0 or xlc_time_camera.xrange[1] ne 0 then xrange=xlc_time_camera.xrange else xrange=0
	lc_plot, zoom=xlc_time_camera.zoom, shift=xlc_time_camera.shift, scale=xlc_time_camera.scale, /externalformat, charsize=1, symsize=xlc_time_camera.symsize, /time,binned=xlc_time_camera.binned, anonymous=xlc_time_camera.anonymous, no_model=~keyword_set(xlc_time_camera.model), no_cleaned=~keyword_set(xlc_time_camera.cleaned), no_var=~keyword_set(xlc_time_camera.variability), no_raw=~keyword_set(xlc_time_camera.raw), no_outliers=~keyword_set(xlc_time_camera.outliers), noright=~keyword_set(xlc_time_camera.histograms), no_intransit=~keyword_set(xlc_time_camera.intransit), eps=keyword_set(xlc_time_camera.eps), png=keyword_set(xlc_time_camera.png), diagnos=xlc_time_camera.diagnostics, compa=xlc_time_camera.comparisons, coordinate_conversions=coordinate_conversions, xrange=xrange

	needtoplot =0B
	xlc_time_coordinate_conversions = coordinate_conversions
	
	if keyword_set(xlc_time_camera.eps) or keyword_set(xlc_time_camera.png) then begin
		xlc_time_camera.eps = 0
		xlc_time_camera.png = 0
		needtoplot = 1B
	endif
endwhile
END ;============= end of xlc_time event handling routine task =============



;------------------------------------------------------------------------------
;	procedure xlc_time
;------------------------------------------------------------------------------
; This routine creates the widget and registers it with the XManager.
;*** This is the main routine for the xlc_time widget.  It creates the
;*** widget and then registers it with the XManager which keeps track of the 
;*** currently active widgets.  
;------------------------------------------------------------------------------
PRO xlc_time, GROUP = GROUP, BLOCK=block, id=id

common xlc_time_common

;*** If xlc_time can have multiple copies running, then delete the following
;*** line and the comment for it.  Often a common block is used that prohibits
;*** multiple copies of the widget application from running.  In this case, 
;*** leave the following line intact.

IF(XRegistered("xlc_time") NE 0) THEN RETURN		;only one instance of
							;the xlc_time widget
							;is allowed.  If it is
							;already managed, do
							;nothing and return

IF N_ELEMENTS(block) EQ 0 THEN block=0

@widget_geometries

; make the main xlc_time window
xlc_timebase = WIDGET_BASE(TITLE = "xlc_time", xsize=width + rightborder + leftborder, ysize=height + topborder + bottomborder, /tlb_size_events)

; define the window's ID so it can be killed externally
id = xlc_timebase

; set up three rows for widget base
toprow_base =  WIDGET_BASE(xlc_timebase, /row, /base_align_center);xoffset=leftborder/2,
	output_buttons_base = widget_base(toprow_base, /row)
	messagebox_base = widget_base(toprow_base, /row)
middlerow_base =  WIDGET_BASE(xlc_timebase, col=3, ysize=height, yoffset=topborder,/base_align_center, frame=3);xoffset=0,
bottomrow_base =  WIDGET_BASE(xlc_timebase, /row,  ysize=bottomborder,yoffset=topborder + height, /base_align_center);xoffset=0,
	outer_goto_base = widget_base(bottomrow_base, /col, /base_align_center, frame=2)
		mjdbox_label = widget_label(outer_goto_base, value='Go to:')
		goto_base = widget_base(outer_goto_base, /row, /base_align_center)
	xrange_base = WIDGET_BASE(bottomrow_base, /row, /base_align_center, frame=0)
	select_base = widget_base(bottomrow_base, /col, /base_align_center, frame=2)
		topselect_base = widget_base(select_base, /row, /base_align_center)
		bottomselect_base = widget_base(select_base, /row, /base_align_center)


; populate top row with buttons controlling output and a message window
eps_button = widget_button(output_buttons_base, uvalue='eps', value='save to EPS', accelerator='Shift+E')
png_button = widget_button(output_buttons_base, uvalue='png', value='save to PNG', accelerator='Shift+P')
ascii_button = widget_button(output_buttons_base, uvalue='ascii', value='save to ASCII', accelerator='Shift+A')
message_label = widget_label(messagebox_base, uvalue='message', value='                                                                                ', frame=1)

; populate options on the left panel
whichlc_values = ['basic', 'variability', 'cleaned']
whichlc_set_value = [1, 1, 1]
whichlc_buttons = cw_bgroup(middlerow_base, whichlc_values, /COLUMN, LABEL_TOP='Light curves:', frame=3,uvalue='whichlc'+whichlc_values, /nonexclus, set_value=whichlc_set_value)

option_values = ['binned', 'model', 'raw', 'outliers', 'in-transit', 'histograms', 'diagnostics','anonymous?']; 'comparisons', 
options_set_value = [0, 1, 0, 1, 0, 1, 0]
option_buttons = cw_bgroup(middlerow_base, option_values, /COLUMN, LABEL_TOP='Options:', frame=3,uvalue='option'+option_values, /nonexclus, set_value=options_set_value)

; create the draw window
draw = WIDGET_DRAW(middlerow_base, XSIZE = width, YSIZE =height, units=0, fram=0, uval='draw', /button_event) 

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
nightbox_label = widget_label(goto_base, value='NIGHT:')
nightbox_text = widget_text(goto_base, uvalue='night', xsize=10, /edit)




;create select buttons
select_button =widget_button( topselect_base, uvalue='select', value='select')
unselect_button =widget_button( topselect_base, uvalue='unselect', value='unselect')
select_label = widget_label(topselect_base, value='0 selected')

ds9_button = widget_button(bottomselect_base, uvalue='ds9', value='ds9', sensitive=0)
censor_button = widget_button(bottomselect_base, uvalue='censor', value='censor', sensitive=0)
context_button = widget_button(bottomselect_base, uvalue='context', value='see in context', sensitive=0)

; bring the whole thing into existence
WIDGET_CONTROL, xlc_timebase, /REALIZE

; figure out what window index correponds to the draw window
WIDGET_CONTROL, draw, GET_VALUE = draw_window 

; first pass at plot
WSET, draw_window 
cleanplot, /silent
loadct, 0
!p.background=255
!p.color=0
plot, [0], /nodata, xs=4, ys=4
lc_plot, zoom=zoom, shift=shift, scale=scale, /externalformat, charsize=1, symsize=0.6, /time, binned=0, /no_raw, /no_int, coordinate_conversions=coordinate_conversions
xlc_time_coordinate_conversions = coordinate_conversions

; define a structure that contains variables needed to keep track of options
xlc_time_camera = {	zoom:zoom, shift:shift, scale:scale, xrange:[0.d,0.d], $
					binned:0, model:1, raw:0, outliers:1, intransit:0, histograms:1, diagnostics:0, comparisons:0, anonymous:0, eps:0, png:0, $
					basic:1, variability:1, cleaned:1, $
					symsize:0.6,  original_scale:scale, $
					base_id:id, middlerow_id:middlerow_base, bottomrow_id:bottomrow_base, draw_id:draw, message_label_id:message_label, select_label_id:select_label,  mjdbox_id:mjdbox_text, $
					setting_range_left:0, setting_range_right:0,$
					draw_window:draw_window}

; register the widget with the xmanager
XManager, "xlc_time", xlc_timebase, $			
		EVENT_HANDLER = "xlc_time_ev", $
		GROUP_LEADER = GROUP, $		
		NO_BLOCK=(NOT(FLOAT(block)))		


END
