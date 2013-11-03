PRO interactive_lc_plot, _extra=_extra

	zoom = 1.0

		light_gray = 220
		medium_gray = 170
		gray = 120

		textoffset =-0.004
		x_offset = 0.007
		y_offset = 0.003
		button_height = [-1, 1]*0.008
		button_width = [-1, 1]*0.01
		big = 6.0

		; display row
		buttons = {$
		; zoom row
		zoom_in:{x:button_width*big, y:button_height, active:0B, label:'magnify time', charsize:1, row:0, uptodate:0},$
		zoom_out:{x:button_width*big, y:button_height, active:0B, label:'shrink time', charsize:1, row:0, uptodate:0},$
		zoom_left:{x:button_width*big, y: button_height, active:0B, label:'shift left', charsize:1, row:0, uptodate:0},$
		zoom_right:{x:button_width*big, y:button_height, active:0B, label:'shift right', charsize:1, row:0, uptodate:0},$
		zoom_vin:{x:button_width*big, y:button_height, active:0B, label:'magnify flux', charsize:1, row:0, uptodate:0},$
		zoom_vout:{x:button_width*big, y:button_height , active:0B, label:'shrink flux', charsize:1, row:0, uptodate:0}$
		}
		rowcount = buttons.(0).row
		for j=1, n_tags(buttons)-1 do  rowcount = [rowcount, buttons.(j).row]
		n_rows = n_elements(uniq(rowcount, sort(rowcount)))

		y_position = 0.98
		for i=0, n_rows-1 do begin
			onthisrow = bytarr(n_tags(buttons))
			total_width = 0.0
			for j=0, n_tags(buttons)-1 do begin
				if buttons.(j).row eq i then begin
					width = max(buttons.(j).x) - min(buttons.(j).x)
					total_width += width
				endif
			endfor
			x_position = 0.5 - total_width/2.0
			for j=0, n_tags(buttons)-1 do begin
				if buttons.(j).row eq i then begin
					width = max(buttons.(j).x) - min(buttons.(j).x)
					buttons.(j).x += x_position + width/2.0
					x_position += width+x_offset
					buttons.(j).y += y_position
					y_jump = max(buttons.(j).y ) - min(buttons.(j).y)
				endif
			endfor
			y_position -= y_jump + y_offset
		endfor	
		!mouse.button=1
		cleanplot, /silent
		screensize = get_screen_size()

		ignore_window = 1

		while(!mouse.button lt 2 and ~ignore_window) do begin
			lc_plot, _extra=_extra, zoom=zoom, shift=shift, scale=scale

			; -----------------------------------
			; draw the buttons!
			; -----------------------------------
			for i=0, n_tags(buttons)-1 do begin
				if ~tag_exist(buttons.(i), 'HIDE') then begin
					polyfill, /normal, buttons.(i).x[[0,0,1,1,0]], buttons.(i).y[[0,1,1,0,0]], thick=2, color=light_gray
					plots, /normal, buttons.(i).x[[0,0,1,1,0]], buttons.(i).y[[0,1,1,0,0]], thick=1, color=medium_gray*(1-buttons.(i).active)
					xyouts, /normal, mean(buttons.(i).x), mean(buttons.(i).y) + textoffset, align=0.5, charsize=buttons.(i).charsize, charthick=1.5, buttons.(i).label, color=gray*(1-buttons.(i).active)
				endif
			endfor

			if ~keyword_set(eps) then  begin
				cursor, xtemp, ytemp, /dev, /now
				if xtemp eq -1 and ytemp eq -1 then mousenotonwindow = 1
				cursor, x, y, /down, /normal

			endif

			;----------------------------------
			; figure out if a button has been pushed
			;----------------------------------
			for i=0, n_tags(buttons)-1 do begin
				if x ge min(buttons.(i).x) and x le max(buttons.(i).x) and y ge min(buttons.(i).y) and y le max(buttons.(i).y) then buttons.(i).active = buttons.(i).active ne 1
			endfor

			;----------------------------------
			; handle zooming
			;----------------------------------
			if buttons.zoom_in.active then begin
				zoom *= 0.5
				buttons.zoom_in.active=0
			endif
			if buttons.zoom_out.active then begin
				zoom *= 2.0
				buttons.zoom_out.active=0
			endif
			if buttons.zoom_right.active then begin
				shift += 0.5
				buttons.zoom_right.active=0
			endif
			if buttons.zoom_left.active then begin
				shift -= 0.5
				buttons.zoom_left.active=0
			endif
			if buttons.zoom_vin.active then begin
				scale *= 0.5
				buttons.zoom_vin.active=0
			endif
			if buttons.zoom_vout.active then begin
				scale *= 2.0
				buttons.zoom_vout.active=0
			endif
	
		endwhile
END