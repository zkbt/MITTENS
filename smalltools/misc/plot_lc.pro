PRO plot_lc, lc, xaxis=xaxis, psym=psym, title=title, time=time, day_marker_height=day_marker_height, symsize_in=symsize_in, moment=moment, set_scale=set_scale, subtle=subtle, xtickunits=xtickunits, phased=phased, noaxes=noaxes, hide=hide, nobad=nobad, colorbar=colorbar, justaxes=justaxes, no_outliers=no_outliers, xtickformat=xtickformat

	if ~keyword_set(colorbar) then colorbar = 0
  if keyword_set(symsize_in) then symsize = symsize_in
	if keyword_set(moment) then begin
		time=1
		xtickunits = 'Hours'

	endif

	if not keyword_set(psym) then begin 
		@psym_circle
		psym=8
	endif

	if not keyword_set(symsize) then symsize=1

	if not keyword_set(title) then title=''
	
	if not keyword_set(xaxis) then begin
  	if keyword_set(time) then begin 
  		xaxis = lc.hjd+ 2400000.5d
  ;		xtitle = 'Time (HJD)'
  	endif else begin
  		xaxis = indgen(n_elements(lc.flux))
  ;		xtitle = 'Sample Number'
  	endelse
  endif
	stretch = 2
	yr = !y.range
	if yr[0] eq yr[1] then begin
		scale = 3*1.48*mad(lc.flux)
		yr = [scale, -scale]
		if keyword_set(set_scale) then !y.range = yr
	endif
  colors = 1.0/lc.fluxerr^2
  colors = (max(colors) - colors)/max(colors)*255.0

  if keyword_set(subtle) then begin
;    loadct, file="~/zkb_colors.tbl", 46, /silent 
    loadct, file="~/zkb_colors.tbl", 54, /silent 

    colors[*] =190
    symsize=0.7*symsize_in
	shrink = 0.7
  endif else begin

	loadct, colorbar, /silent, file="~/zkb_colors.tbl"
	shrink = 1
endelse  
  !y.style = 1
  !x.style = 3
  if keyword_set(subtle) or keyword_set(noaxes) then begin
    !y.style = !y.style or 4
    !x.style = !x.style or 4
  endif

  
	plot, xaxis, lc.flux, yrange=yr, psym=psym, symsize=symsize, xtickunits=xtickunits, /nodata, xtickformat=xtickformat
	if keyword_set(moment) then vline, moment+2400000.5d, linestyle=1

	if ~keyword_set(justaxies) then begin
		i_bad = where(lc.okay eq 0, complement=i_good, n_bad)
		
		if i_good[0] ne -1 and ~keyword_set(hide) then plots, xaxis[i_good], lc[i_good].flux, color=colors, psym=psym, symsize=symsize*shrink, noclip=0
		if n_bad gt 0 and ~keyword_set(hide) and ~keyword_set(nobad) then plots, xaxis[i_bad], lc[i_bad].flux, color=colors[i_bad], psym=7, symsize=symsize, noclip=0, thick=1
			if i_good[0] ne -1 and ~keyword_set(hide) and ~keyword_set(no_outliers) then oplot_outliers, lc[i_good].flux,  hjd=xaxis[i_good], color=colors 
			if keyword_set(errplot) then errplot, xaxis, lc.flux-lc.fluxerr, lc.flux+lc.fluxerr
		loadct, file="~/zkb_colors.tbl", 54, /silent 
	endif

	day_marker_height = abs(yr[0] - yr[1])/10.0
	if not keyword_set(time) then begin
		oplot_days, lc.hjd, -yr[1], /top
;   		 for i=0, n_elements(lc.hjd)-2 do begin
; 			if lc[i+1].hjd - lc[i].hjd gt 0.5 then begin
; 				oplot, [i,i]+0.5, [yr[0], yr[0]-day_marker_height], color=180
; 				oplot, [i,i]+0.5, [yr[1], yr[1]+day_marker_height], color=180
; 			endif
; 		endfor
	endif

END