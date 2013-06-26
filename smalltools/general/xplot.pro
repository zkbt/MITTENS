PRO xplot, i, xsize=xsize, ysize=ysize, title=title, free=free, xpos=xpos, ypos=ypos, top=top
;+
; NAME:
;    
;	xplot
; 
; PURPOSE:
; 
;	sets IDL up to plot to the screen, using a pretty white background
; 
; CALLING SEQUENCE:
; 
;	xplot, 42
; 
; INPUTS:
;	
;	i = the index for the window (for having multiple windows open at once)
; 
; KEYWORD PARAMETERS:
; 
;	all the other keyword parameters get passed on to IDL "window" function
; 
; OUTPUTS:
; 
;	(none)
; 
; RESTRICTIONS:
; 
;	probably lots
;
; EXAMPLE:
; 
;	xplot, 42, xsize=1000, ysize=500, title="This appears at the top of the window.", xpos=100, ypos=200	
; 
; MODIFICATION HISTORY:
;
; 	written by Zach Berta-Thompson, sometime before 2013.
;
;-
	if n_elements(top) eq 0 then top=1
	set_plot, 'x'
	if ~keyword_set(i) then i = 0
	window, i, xsize=xsize, ysize=ysize, title=title, free=free, xpos=xpos, ypos=ypos
	device, decomposed=0
	!p.background=255
	!p.color=0
	erase
	if not keyword_set(top) then wshow, i, 0
END
