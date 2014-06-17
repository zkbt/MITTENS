FUNCTION refine_candidate, candidate, eps=eps, res=res, asof=asof, zoom=zoom
	common this_star
	restore, star_dir + 'box_pdf.idl'
	
	if keyword_set(asof) then begin
		boxes = boxes[where(boxes.hjd le asof)]
		print, 'looking at candidate significance as of', asof
	endif
	if ~keyword_set(res) then	res =1000
	if ~keyword_set(zoom) then zoom = 1.0
	period_span = candidate.period/600/zoom
	periods = candidate.period + (dindgen(res+1)/res - 0.5)*period_span
	hjd0_span = (2*candidate.duration/zoom < candidate.period) > 5*candidate.duration
	hjd0_res = res/10 < (hjd0_span/(1.0/60.0/24.0))

	; RECENTER THE HJD0!
	candidate.hjd0 = round((mean(boxes.hjd) - candidate.hjd0)/candidate.period) * candidate.period + candidate.hjd0
	hjd0 = candidate.hjd0 + (dindgen(hjd0_res+1)/hjd0_res - 0.5)*hjd0_span
;	hjd0 = an_hjd_in_the_midpoint + (dindgen(hjd0_res+1)/hjd0_res - 0.5)*hjd0_span
	grid = fltarr(res+1,hjd0_res+1)
	depth_grid = fltarr(res+1,hjd0_res+1)
	depth_uncertainty_grid =  fltarr(res+1,hjd0_res+1)
	refined_candidates = replicate(candidate, res+1,hjd0_res+1)
	for i=0, res-1 do begin
		for j=0, hjd0_res-1 do begin
			temp_candidate = candidate
			temp_candidate.period = periods[i]
			temp_candidate.hjd0 = hjd0[j]
			temp_candidate = box_folding_robot(temp_candidate, boxes, nights=nights, pad=pad, k=k)
			grid[i,j] = temp_candidate.depth/temp_candidate.depth_uncertainty
			depth_grid[i,j] = temp_candidate.depth
			depth_uncertainty_grid[i,j] = temp_candidate.depth_uncertainty

		endfor
		counter, i, res
	endfor
filename = star_dir + 'plots/prediction_' + string(format='(F09.6)', candidate.period)
if keyword_set(asof) then filename += '_asof'+rw(string(asof))
filename +='.eps'
if keyword_set(eps) then begin
	set_plot, 'ps'
	device, filename=filename, /encap, /color, xsize=20, ysize=20, /inches, /helvetica
	!p.font = 0
endif else xplot, xsize=1000, ysize=1000
		smultiplot, /init, [2,3], colw=[1, .2], ygap=0.03, rowh=[1,.4,.8]
		smultiplot, /dox
		levels = [-100.0, 0.0, 0.5, 1, 1.5, 2, 2.5 ,3, 3.5, 4, 4.5 ,5, 5.5,6,6.5,7,7.5]
		if keyword_set(asof) then today = mjdtodate(asof) else today = mjdtodate(max(boxes.hjd))
		contour, grid, periods - candidate.period, hjd0 - candidate.hjd0, levels=[levels, max(levels)+1], /fill, title='lspm' + rw(mo_info.lspmn) + ' using data up to '+ rw(today) + '; Period = ' + rw(string(candidate.period, format='(D20.7)')) + ' days, modified HJD0 = ' + rw(string(candidate.hjd0, format='(D20.7)')) + ', duration = ' + rw(string(candidate.duration*24, format='(F4.2)')) + ' hours', xtitle='Period - ' + rw(string(candidate.period, format='(D20.7)'))  + ' (days)', ytitle='HJDo - '+string(format='(F13.5)', candidate.hjd0+2400000.5d)+ ' (days)', xs=3, ys=3


		smultiplot
		loadct, 39
		plot, [0], xs=4, ys=4
		usersym, [-1,1,1,-1,-1], [-1,-1,1,1,-1], /fill
		al_legend, goodtex('D/\sigma') +'>' +string(form='(F3.1)', levels), colors=findgen(n_elements(levels))*254/n_elements(levels), psym=8, box=0
		thresholds = max(grid) -[0.01, 0.1, 0.5, 1.0];[6.5] [8.0, 7.5, 7.0];
		k = where(grid gt min(thresholds), n_threshold)
		smultiplot, /dox

		if n_threshold gt 0 then begin
			ai = array_indices(grid, k)
			decent = struct_conv({period:reform(periods[ai[0,*]]), hjd0:reform(hjd0[ai[1,*]]), depth:depth_grid[k], depth_uncertainty:depth_uncertainty_grid[k], duration:candidate.duration*ones(n_threshold)})
	;		plots, decent.period, decent.hjd0, psym=8
						i_today = round(((systime(/jul) - 2400000.5d) - candidate.hjd0)/candidate.period)

						events = (decent.hjd0 + decent.period*i_today ) - (candidate.hjd0 + candidate.period*i_today)

			yr =[0, max(histogram(events, bin=0.1))]			
; 			if n_elements(decent) gt 3 then begin
; 				i_today = round(((systime(/jul) - 2400000.5d) - candidate.hjd0)/candidate.period)
; 				events = (decent.hjd0 + decent.period*i_today ) - (candidate.hjd0 + candidate.period*i_today)
; 				plothist, events*24,  bin=0.1, xtitle='Possible Offsets from Transit Time Prediction (hours) !Cnear '+systime(), xr=[-1,1]*(12 < 3*max(abs(events*24))), ys=4
; 				
; 
; 			endif
		endif
		if ~keyword_set(asof) then	save, filename=star_dir+'predictions/'+ rw(string(date_conv(systime(/jul)))) + '_' + string(format='(D010.7)', candidate.period) + '_' +string(format='(D05.3)', candidate.duration) + '.idl', decent, periods, hjd0, depth_grid, depth_uncertainty_grid
		hist = 0
		for i =0, n_elements(thresholds)-1 do begin
				k = where(grid gt thresholds[i], n_threshold)
				if n_threshold gt 0 then begin
				;	ai = array_indices(grid, k)
				;	decent = struct_conv({period:reform(periods[ai[0,*]]), hjd0:reform(hjd0[ai[1,*]]), depth:depth_grid[k], depth_uncertainty:depth_uncertainty_grid[k], duration:candidate.duration*ones(n_threshold)})
				;	plots, decent.period, decent.hjd0, psym=8
					i_this = where(decent.depth/decent.depth_uncertainty gt thresholds[i], n_pass)
					if n_pass eq 0 then continue
					
					if n_elements(decent[i_this]) gt 1 then begin
						i_today = round(((systime(/jul) - 2400000.5d) - candidate.hjd0)/candidate.period)
						events = (decent[i_this].hjd0 + decent[i_this].period*i_today ) - (candidate.hjd0 + candidate.period*i_today)
						
						print, yr
						plothist, events*24,  bin=0.1, thick=2*(n_elements(thresholds) - i), over=hist, xr=[-5, 5]*2, ys=7, yr=yr, color=0, xtitle='Hours from Predicted Mid-transit'
						hist  = 1
						print, 'above ', thresholds[i]
						print, '    offset of ', mean(events*24) , ' +/- ', stddev(events*24), ' expected'

					endif
				endif
		endfor
		al_legend, goodtex('D/\sigma') +'>' + string(thresholds, form='(F4.2)'), linestyle=0, thick=(n_elements(thresholds)-indgen(n_elements(thresholds)))*2, /bottom, /right, box=0

		smultiplot
		smultiplot
		plot, [0], xs=5, ys=5, xr=[0,1], yr=[0,1]
		str = 'RECENT AND UPCOMING EVENTS (dates heliocentric UT):!C!C'
		i_today = round(((systime(/jul) - 2400000.5d) - candidate.hjd0)/candidate.period)

		if n_elements(decent) gt 0 then begin
			for i=-10, 10 do begin
				
				mjd_event = candidate.hjd0 + candidate.period*(i_today+i)
				jd_event = mjd_event + 2400000.5d
				str += '     #' + rw(i_today + i) + ' = ' + string(mjd_event, format='(F10.4)') + ' = '  +  date_conv(jd_event, 'S') 
				
				for j=0, n_elements(thresholds)-1 do begin
					i_this = where(decent.depth/decent.depth_uncertainty gt thresholds[j], n_pass)
					if n_pass eq 0 then continue
					offsets = ((decent[i_this].hjd0 + decent[i_this].period*(i_today+i)) - mjd_event)*24.0	
					lower_uncertainty =min(offsets)*(-1)
					upper_uncertainty = max(offsets)
		
					str += ' (+ ' + rw(string(format = '(F5.2)', upper_uncertainty)) + ', -' + rw(string(format = '(F5.2)', lower_uncertainty)) + ' hours' +  '['+string(form='(F4.2)', thresholds[j])+' sigma])'
				endfor
				str += '!C'
			endfor
		endif
		if keyword_set(eps) then DEVICE, SET_FONT='Courier'
		!p.font = 1
		xyouts, 0.05, 0.9, str, /data, align=0.0, charsize=0.8, font=0
		smultiplot, /def

if keyword_set(eps) then begin
	device, /close
	set_plot, 'x'
	epstopdf, filename
	epstopng, filename, /hide
	if keyword_set(asof) then begin
		filestoanimate =  star_dir() + 'plots/prediction_' + string(format='(F09.6)', candidate.period) + '_asof' + '*.png'
		output = star_dir() + 'plots/prediction_' + string(format='(F09.6)', candidate.period) + '_animated.gif'
		spawn, 'convert -delay 100 '+filestoanimate + ' -loop 0  ' + output
	endif
endif


END