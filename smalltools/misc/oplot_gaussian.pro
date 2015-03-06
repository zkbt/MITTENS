PRO oplot_gaussian, y, linestyle=linestyle, color=color, bin=bin, rotate=rotate, thick=thick, pdf_params=pdf_params, center=center, sigma=sigma, rms=rms
;+
; NAME:
;	oplot_gaussian
;
; PURPOSE:
;	oplot a Gaussian on top of a histogram of given values
;
; INPUTS:
;	y			| values going into the histogram
;	bin=			| binsize of the already plotted histogram
;-
; removed switched sigma to a keyword output, 8/21/2012

	n_bins = (max(y) - min(y))/bin > 1
	x = dindgen(n_bins)*bin + min(y)
;	x = (findgen(1000)/500 - 1.0)*max(abs(y))

if keyword_set(pdf_params) then begin
	center = pdf_params[0]
	sigma = pdf_params[1]
endif else begin
	center = median(y)
	sigma = 1.4*mad(y)
	if keyword_set(rms) then sigma = stddev(y)
endelse

	if keyword_set(rotate) then begin
	 x_plot = 1.0/sqrt(2*!pi)/sigma*exp(-(x-center)^2/2/sigma^2)*n_elements(y)*bin
	 y_plot = x
  endif else begin
    x_plot = x
    y_plot = 1.0/sqrt(2*!pi)/sigma*exp(-(x-center)^2/2/sigma^2)*n_elements(y)*bin
  endelse 
	oplot, x_plot, y_plot, linestyle=linestyle, color=color, thick=thick
END