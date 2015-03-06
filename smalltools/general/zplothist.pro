PRO zplothist, vector, bin=bin, rotate=rotate, log=log, color=color, gauss=gauss, overplot=overplot, xstyle=xstyle, ystyle=style, yrange=yrange, pdf_params=pdf_params, thick=thick, only=only, line_fill=line_fill, spacing=spacing, orientation=orientation, linestyle=linestyle
    if not keyword_set(bin) then bin=1
    if not keyword_set(color) then color = 170
    if not keyword_set(thick) then thick=4
	if n_elements(only) eq 0 then only = lindgen(n_elements(vector))
    if n_elements(vector) eq 1 then y = [vector[only], vector[only]] else y = vector[only]
	if total(finite(y)) eq 0 then return
	trimmed = y
    h = histogram(y, bin=bin, locations=locations, /nan)
    if n_elements(vector) eq 1 then h /= 2.0
    if keyword_set(rotate) then begin
      x = h
      y = locations + bin/2.0
      xlog = keyword_set(log)
    endif else begin
      x = locations + bin/2.0
      y = h
      ylog = keyword_set(log)
    endelse
; 	if keyword_set(only) then begin
; 		x = x[only]
; 		y = y[only]
; 	endif
    if not keyword_set(overplot) then plot, x, y, /nodata, xlog=xlog, ylog=ylog, xstyle=xstyle, ystyle=style, yrange=yrange
    if keyword_set(rotate) then for i=0, n_elements(x)-1 do polyfill, noclip=0, color=color, x[i]*[0, 1, 1, 0], y[i] + [-bin, -bin, bin, bin]/2., line_fill=line_fill, spacing=spacing, orientation=orientation else for i=0, n_elements(h)-1 do polyfill, color=175, x[i] + [-bin, -bin, bin, bin]/2., y[i]*[0, 1, 1, 0], noclip=0, line_fill=line_fill, spacing=spacing, orientation=orientation, linestyle=linestyle

 ;   loadct, 54, /silent, file='~/zkb_colors.tbl'
    loadct, 0, /silent
    !p.thick=2
    if keyword_set(gauss) then oplot_gaussian, trimmed, pdf_params=pdf_params, bin=bin, color=0, rotate=rotate, thick=thick
  END