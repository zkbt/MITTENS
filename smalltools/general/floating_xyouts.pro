PRO floating_xyouts, x, y, text, align=align, charsize=charsize, charthick=charthick, color=color, bgcolor=bgcolor
	if n_elements(bgcolor) eq 0 then bgcolor=255
	if n_elements(charthick) eq 0 then charthick=1

	xyouts, x, y, text, align=align, charsize=charsize, charthick=charthick*5, color=bgcolor
	xyouts, x, y, text, align=align, charsize=charsize, charthick=charthick, color=color
END