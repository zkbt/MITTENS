FUNCTION smulti_datacoord, event=event, coordinate_converstions=coordinate_conversions, geometry=geometry
	; function uses stored coordinate conversion parameters and the click from a draw event to return the data coordinates of a click (and which subpanel of a smultiplot series was clicked)

	; event must be a draw event
	; coordinate conversions must at least contain x, y, p tags for !X, !Y, and !P
	pixel_click = {x:double(event.x), y:double(event.y)}
	for i=0, n_elements(coordinate_conversions)-1 do begin

		; these lines account for arbitrary smultiplot panels
		normal_position = coordinate_conversions[i].p.position
		pixel_xrange = [normal_position[0], normal_position[2]]*geometry.xsize
		pixel_yrange = [normal_position[1], normal_position[3]]*geometry.ysize
		in_this_plot = pixel_click.x ge pixel_xrange[0] and pixel_click.x le pixel_xrange[1] and pixel_click.y ge pixel_yrange[0] and pixel_click.y le pixel_yrange[1]

		; this line account for there being only one possible plot window (so !p.position isn't set)
		in_this_plot = in_this_plot or (coordinate_conversions[i].p.position[0] eq 0 and coordinate_conversions[i].p.position[1] eq 0 and coordinate_conversions[i].p.position[2] eq 0 and coordinate_conversions[i].p.position[3] eq 0)
		if in_this_plot then begin
			!x = coordinate_conversions[i].x
			!y = coordinate_conversions[i].y
			!p = coordinate_conversions[i].p
			click = convert_coord(pixel_click.x, pixel_click.y, /device, /data)
			return, {x:click[0], y:click[1], which:i}
		endif else i_plot = -1

	endfor

END