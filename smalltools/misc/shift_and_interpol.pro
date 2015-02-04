FUNCTION shift_and_interpol, y_input, y_destination, applied_offset=applied_offset
	oversample = 100.0
	smooth_factor = 100.0

	input_divide_out = smooth(y_input, smooth_factor)
	x_input = findgen(n_elements(y_input))
	n_input = n_elements(y_input)
	grid_input = findgen(oversample*n_input)*(max(x_input) - min(x_input))/(oversample*n_input-1) + min(x_input)
	y_input_oversampled = smooth(rebin(y_input, oversample*n_input), oversample)
	input_divide_out = smooth(y_input_oversampled, oversample*smooth_factor)
	y_input_oversampled /= input_divide_out

	destination_divide_out = smooth(y_destination, smooth_factor)
	x_destination = findgen(n_elements(y_destination))
	n_destination = n_elements(y_destination)
	grid_destination = findgen(oversample*n_destination)*(max(x_destination) - min(x_destination))/(oversample*n_destination-1) + min(x_destination)
	y_destination_oversampled = smooth(rebin(y_destination, oversample*n_destination), oversample)
	destination_divide_out = smooth(y_destination_oversampled, oversample*smooth_factor)
	y_destination_oversampled /= destination_divide_out

	!p.multi=[0,1,3]
;	xplot
;	loadct, 39, /silent
;	plot, grid_input, y_input_oversampled, psym=3
;	oplot, x_input, y_input, psym=1, color=250

;	plot, grid_destination, y_destination_oversampled,  psym=3
;	oplot, x_destination, y_destination, psym=1, color=250
	max_pixel_shift = 2.0
	lags = findgen(oversample*max_pixel_shift + 1) - max_pixel_shift*oversample/2
	cc = c_correlate(y_input_oversampled, y_destination_oversampled, lags, /double)
;	plot, lags/oversample, cc, /ystyle, xrange=[-5,5]
	i = where(cc eq max(cc))
	print, lags[i]/oversample
	shifted_indices = (-lags[i[0]] + lindgen(n_input*oversample) )< (n_input*oversample) > 0
	applied_offset = -lags[i[0]]/oversample
	y_input_oversampled *= input_divide_out
	return, rebin(y_input_oversampled[shifted_indices], n_destination)
END