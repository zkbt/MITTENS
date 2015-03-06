PRO fried_egg, x, y, res=res, overplot=overplot, fill=fill, enclosed_fractions=enclosed_fractions, c_thick=c_thick, c_color=c_color, reverse_colors=reverse_colors,  xrange=xrange, yrange=yrange, title=title, xtitle=xtitle, ytitle=ytitle, isotropic=isotropic, xstyle=xstyle, ystyle=ystyle
;+
; NAME:
;	fried_egg
; PURPOSE:
;	plot iso-density contours that contain specified fractions of a 2D distribution (such plots can occasionally take on the appearance of a sunny-side-up egg)
; CALLING SEQUENCE:
;	fried_egg, x, y, [res=res, overplot=overplot, color=color, xrange=xrange, yrange=yrange, title=title, fill=fill]
; INPUTS:
;	x	is one array
;	y	is another array, the same size as x
; KEYWORD PARAMETERS:
;	res = res 			--- the number of bins with which you'd like to use divide the plot window, applies to both dimensions (default is res=30)
;	enclosed_fractions = enclosed_fractions ---	an array. for each element in it, a contour will be drawn enclosing that fraction of the distribution, defaults to [0.95, 0.68]
;	/overplot			--- activate this keyword if you would like to overplot the contours on an already existing plot
;	/fill				--- activate this keyword if you would like the contours to be filled
; 	c_color = c_color	--- set the colors of the contours, can be a scalar or an array with the same number of elements as enclosed_fraction, defaults to darker central contours for most color tables
;	/reverse_colors	--- activate this keyword to switch the order of the colors
; 	c_thick = c_thick	--- set the colors of the levels, can be a scalar or an array with the same number of elements as enclosed_fraction, defaults to thicker central contours
;	(other)			--- a bunch of graphics keywords are allowed, that will be passed to the contour command
; OUTPUTS:
;	(none)
; RESTRICTIONS:
;	(probably lots)
; EXAMPLE:
; 	n = 1e6 & x = randomn(seed, n) & y = randomn(seed, n)+sin(2*x)*2  & fried_egg, x, y, res=50, enclosed_fractions=[0.99, 0.95, 0.68], /fill, c_color=[230, 150, 70]
; MODIFICATION HISTORY:
; 	Written by Zach Berta (zberta@cfa.harvard.edu) as part of the
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-
	
	if not keyword_set(res) then res=30
	n = n_elements(x)
	if keyword_set(xrange) then begin
		min_x = xrange[0]
		max_x = xrange[1]
	endif else begin
		min_x = min(x)
		max_x = max(x)
	endelse
	bin_x = (max_x - min_x)/(res)
	binedge_x = bin_x*findgen(res) + min_x
	axis_x = 0.5*bin_x + binedge_x
	if keyword_set(yrange) then begin
		min_y = yrange[0]
		max_y = yrange[1]
	endif else begin
		min_y = min(y)
		max_y = max(y)
	endelse
	bin_y = (max_y - min_y)/(res)
	binedge_y = bin_y*findgen(res) + min_y
	axis_y = 0.5*bin_y + binedge_y
	i_offplot = where(x gt max_x or y gt max_y or x lt min_x or y lt min_y, n_offplot, complement=i_onplot)
	h = hist_2d(value_locate(binedge_x, x[i_onplot]), value_locate(binedge_y, y[i_onplot]), min1=0, max1=res, min2=0, max2=res)
	hh = histogram(h, reverse_indices=ri, min=0, locations=locations)


	if not keyword_set(enclosed_fractions) then begin
		sigma = [2,1]
		enclosed_fractions = erf(sigma/sqrt(2))
	endif

	levels = [value_locate(total((hh*locations), /cumulative), (1.0-enclosed_fractions)*n - n_offplot)]
	i = where(levels ge 0,n)
	i = i[uniq(levels[i])]
	i = i[reverse(sort(enclosed_fractions[i]))]

	if n_elements(c_thick) eq  n_elements(enclosed_fractions) then c_thick = c_thick[i]
	if n_elements(c_thick) eq 0 then c_thick = (indgen(n) + 1)*4.0/n
	max_color =  200.0
	min_color = 0.0
	level_colors = interpol([min_color, max_color], [0., n-1.], n-indgen(n)-1)
	print, level_colors
	if n_elements(c_color) eq 1 then level_colors = intarr(n) + c_color
	if n_elements(c_color) eq n_elements(enclosed_fractions) then level_colors = c_color[i]
	if keyword_set(reverse_colors) then level_colors = reverse(level_colors)

	contour, h[1:res-1, 1:res-1], axis_x[1:res-1], axis_y[1:res-1], levels=[levels[i], max(h)+1],  c_thick=c_thick, overplot=overplot,  /close, xrange=xrange, yrange=yrange, fill=fill, c_color=[level_colors, 255], title=title,  isotropic=isotropic,   xtitle=xtitle, ytitle=ytitle, xstyle=xstyle, ystyle=ystyle

END