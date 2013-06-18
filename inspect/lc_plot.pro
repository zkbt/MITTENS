FUNCTION lc_xaxis

END

FUNCTION trimlongdate, axis, index, value, level
	if value gt 2400000.5d and value le 2500000.5d then begin
		trimmed = value - 2450000.5
		str = rw(string(trimmed, form='(D10.5)'))
	;	if index eq 0 then str = "HJD - 2450000.5 = " + str
		return, str
	endif
	return, label_date(Axis, Index, Value, level)
END	


PRO lc_plot, time=time, night=night, transit=transit, eps=eps, phased=phased, candidate=candidate, fixed=fixed, wtitle=wtitle, lcs=lcs, sin=sin, number=transit_number, diagnosis=diagnosis, comparisons=comparisons, xrange=xrange, pdf=pdf, no_basic=no_basic, no_variability=no_variability, no_cleaned=no_cleaned, box=box, xmargin=xmargin, ymargin=ymargin, censorship=censorship, top=top, png=png, event=event, anonymous=anonymous, externalformatting=externalformatting, charsize=charsize, noleft=noleft, noright=noright, symsize=symsize, replacementtitle=replacementtitle, addspace=addspace, noxtitle=noxtitle, offset=offset, fake=fake, n_durations=n_durations, zoom=zoom, shift=shift, scale=scale, binned=binned, n_bins=n_bins, xpos=xpos, ypos=ypos, hatlen=hatlen, label=label, no_model=no_model, no_raw=no_raw, no_outliers=no_outliers, no_intransit=no_intransit, coordinate_conversions=coordinate_conversions

;+
; NAME:
;    
;	lc_plot
; 
; PURPOSE:
; 
;	a plotting engine, to load up a MEarth light curve, and plot it with lots of different options
; 
; CALLING SEQUENCE:
; 
;	set_star, 1186, /comb
;	plot_lc, no_outliers=no_outliers, [many options]
; 
; INPUTS:
; 
; KEYWORD PARAMETERS:
; 
;	
; 
; OUTPUTS:
; 
;	
; 
; RESTRICTIONS:
; 
;	
; 
; EXAMPLE:
; 
;	
; 
; MODIFICATION HISTORY:
;
; 	Written by ZKB.
;
;-


	; load environments for mearth tools, and for this star in particular
	common this_star
	common mearth_tools

; =============================
; load light curves
; =============================

	if file_test(star_dir + 'target_lc.idl') eq 0 then begin
		mprint, skipping_string, "can't plot non-existent light curves!"
	endif

	if keyword_set(png) then eps =1


	; define the core of a plotting light curve structure
	lc_point = {x:0.0d, hjd:0.0d, flux:0.0, fluxerr:0.0, okay:0B, intransit:0B}

	; UNCORRECTED
	lc_titles = 'Basic MEarth!CPhotometry!C(mag.)'												; define a title
	restore, star_dir + 'inflated_lc.idl'															; restore the basic light curve
	if n_elements(segments_boundaries) eq 0 then segments_boundaries  = n_elements(inflated_lc)-1	; define the segment boundaries, if they weren't defined in inflated_lc.idl
	lc = replicate(lc_point, n_elements(inflated_lc))												; create a plotting lightcurve structure array
	copy_struct, inflated_lc, lc																; fill up a plotting light curve with the basic light curve
	lcs = create_struct('uncorrected', lc)														; create the head of a jellyfish to contain all different lightcurves
	restore, star_dir + 'raw_target_lc.idl'														; restore the raw (unbinned) light curve
	raw_lc = replicate(lc_point, n_elements(target_lc))											; create a plotting lightcurve structure array for the raw light curve
	copy_struct, target_lc, raw_lc																; fill up a raw plotting light curve with the raw basic light curve
	raw_lcs = create_struct('uncorrected', raw_lc)												; create the jellyfish to hold  different raw light curves

	; VARIABILITY
		restore, star_dir + 'variability_lc.idl'

	if ~keyword_set(no_variability) then begin												; sometimes, might not want to plot variability
		lc_titles = [lc_titles, 'Stellar!CVariability!C(mag.)']										; set up everything else as for basic light curves above
		lc = replicate(lc_point, n_elements(variability_lc))
		copy_struct, variability_lc, lc
		lcs = create_struct(lcs, 'variability', lc)
		raw_lc = raw_lcs.uncorrected
		raw_lc.flux = zinterpol(lcs.variability.flux - lcs.uncorrected.flux, lcs.uncorrected.hjd, raw_lcs.uncorrected.hjd)+ raw_lcs.uncorrected.flux
		raw_lcs = create_struct(raw_lcs, 'variability', raw_lc)
	endif

	restore, star_dir + 'cleaned_lc.idl'
	if ~keyword_set(no_cleaned) then begin													; sometimes, might not want to plot cleaned light curve
		lc_titles = [lc_titles, 'Residuals!C(mag.)']												; set up everything else as below
		lc = replicate(lc_point, n_elements(cleaned_lc))
		copy_struct, cleaned_lc, lc
		lcs = create_struct(lcs, 'cleaned', lc)
		raw_lc = raw_lcs.uncorrected
		raw_lc.flux = zinterpol(lcs.cleaned.flux - interpol(lcs.uncorrected.flux,lcs.uncorrected.hjd, lcs.cleaned.hjd), lcs.cleaned.hjd, raw_lcs.uncorrected.hjd) + raw_lcs.uncorrected.flux
		raw_lcs = create_struct(raw_lcs, 'cleaned', raw_lc)
	endif

	; stats about light curve jellyfish
	n_lc = n_tags(lcs)
	tags_of_lc = tag_names(lcs)

	; set up an array for censoring data (1= okay, 0 = bad)
	if n_elements(censorship) eq 0 then censorship = ones(n_elements(lcs.(0)))
	for i=0, n_lc-1 do lcs.(i).okay = lcs.(i).okay and censorship

; =============================
; basic plotting setup
; =============================

	theta = findgen(21)/20*2*!pi
	loadct, 39, /silent

	if ~keyword_set(externalformatting) then cleanplot, /silent
	if ~keyword_set(externalformatting) then !p.charsize=0.7 else !p.charsize=charsize
	if ~keyword_set(event) and ~keyword_set(externalformatting) then !p.charsize=1
	if keyword_set(xmargin)  then !x.margin = xmargin else !x.margin=[12,2]
	if keyword_set(ymargin)  then !y.margin = ymargin else !y.margin =[4+3*(keyword_set(time) AND ~keyword_set(phased)), 4]
	!y.ticklen = 0.01
	ygap = 0.01
	title=star_dir
	if ~keyword_set(scale) then begin
		scale = 0 
		for i=0, n_lc-1 do scale=5*mad(lcs.(i).flux) > scale
		if keyword_set(candidate) then scale = scale > candidate.depth*2
		scale = scale <(10*1.58*mad(lcs.cleaned.flux))
	endif

; =============================
; set up the x-axis
;     (there are a lot of decisions to make here)
; =============================

	if keyword_set(box) then begin
		night = box.hjd
		time = 1
	endif
	if keyword_set(time) then begin
		for i=0, n_lc-1 do begin
			lcs.(i).x = lcs.(i).hjd + 2400000.5d
			raw_lcs.(i).x = raw_lcs.(i).hjd + 2400000.5d
		endfor
		!x.charsize=0.0001
	endif else begin
		for i=0, n_lc-1 do begin
			lcs.(i).x = interpol(indgen(n_elements(lcs.(0))), lcs.(0)[sort(lcs.(0).hjd)].hjd, lcs.(i).hjd)
			raw_lcs.(i).x = interpol(lcs.(i).x,  lcs.(i)[sort(lcs.(i).hjd)].hjd, raw_lcs.(i).hjd) 
			raw_lcs.(i).x = raw_lcs.(i).x > 0
			raw_lcs.(i).x = raw_lcs.(i).x < (n_elements(lcs.(0))-1)
		endfor
	endelse
	if keyword_set(candidate) then begin
		for i=0, n_lc-1 do begin
			; unbinned light curves
			pad = long((max(raw_lcs.(i).hjd) - min(raw_lcs.(i).hjd))/candidate.period) + 1
			if keyword_set(sin) then begin 
				phased_time = (raw_lcs.(i).hjd-sin.hjd0)/sin.period + pad + 0.5
				orbit_number = long(phased_time)
				if keyword_set(phased) then raw_lcs.(i).x = (phased_time - orbit_number - 0.5)*sin.period*24
				; light curves
				pad = long((max(lcs.(i).hjd) - min(lcs.(i).hjd))/sin.period) + 1
				phased_time = (lcs.(i).hjd-sin.hjd0)/sin.period + pad + 0.5
				orbit_number = long(phased_time)
				if keyword_set(phased) then lcs.(i).x = (phased_time - orbit_number - 0.5)*sin.period*24
			endif else begin
				phased_time = (raw_lcs.(i).hjd-candidate.hjd0)/candidate.period + pad + 0.5
				orbit_number = long(phased_time)
				if keyword_set(phased) then raw_lcs.(i).x = (phased_time - orbit_number - 0.5)*candidate.period*24
				; light curves
				pad = long((max(lcs.(i).hjd) - min(lcs.(i).hjd))/candidate.period) + 1
				phased_time = (lcs.(i).hjd-candidate.hjd0)/candidate.period + pad + 0.5
				orbit_number = long(phased_time)
				if keyword_set(phased) then lcs.(i).x = (phased_time - orbit_number - 0.5)*candidate.period*24
			endelse
			lcs.(i).intransit = in_an_intransit_box;abs((phased_time - orbit_number - 0.5)*candidate.period) lt candidate.duration/2
		endfor		
		transit = {hjd0:0.0, duration:candidate.duration, depth:candidate.depth, depth_uncertainty:candidate.depth_uncertainty}		
		xtickunits = ''
	endif
	if ~keyword_set(zoom) then zoom = 1.0
	if ~keyword_set(shift) then shift = 0.0
	; set xrange
	if keyword_set(xrange) then !x.range = xrange else begin
		center = mean(range(raw_lcs.(0).x))
		span = max(raw_lcs.(0).x) - min(raw_lcs.(0).x) 
		!x.range = center + [-1, 1]*0.5*span*zoom
		if ~keyword_set(n_durations) then n_durations = 5
		if keyword_set(phased) or keyword_set(event) then begin
			 if keyword_set(sin) then !x.range = ([-0.5, 0.5] + shift)*sin.period*24*zoom else begin
				!x.range = ([-0.5, 0.5] + shift)*candidate.period*24*zoom
				;if keyword_set(binned) then   else  !x.range = ([-0.5, 0.5] + shift)*transit.duration*24*n_durations*zoom
			endelse
		endif
	endelse




	if keyword_set(night) then begin
; 		; GOING TO SCREW UP PLOTTING INDIVIDUAL NIGHTS WITHOUT TRANSITS!
		i_rawnight = where(abs(raw_lcs.(0).hjd - night) lt 8.0/24.0, n_rawnight)
		i_night = where(abs( inflated_lc.hjd - night) lt 8.0/24.0, n_night)
		if n_rawnight gt 0 then begin
			if keyword_set(time) then begin
				!x.range = box.hjd + 2400000.5d + [-5, 5]/24.0
			endif else begin
				!x.range=[min(i_night), max(i_night)]
			endelse
		endif else return
	endif
 
	if keyword_set(box) and keyword_set(event) then begin
		for i=0, n_lc-1 do begin
			raw_lcs.(i).x = (raw_lcs.(i).hjd - box.hjd)*24
			lcs.(i).x = (lcs.(i).hjd - box.hjd)*24
		endfor
		!x.range = ([-0.5, 0.5] + shift)*transit.duration*5*24 *zoom
	endif

	if keyword_set(xrange) then !x.range = xrange


	if keyword_set(phased) or keyword_set(box) then begin
		x_vertices = [min(!x.range), -candidate.duration/2.0*24, -candidate.duration/2.0*24, candidate.duration/2.0*24, candidate.duration/2.0*24, max(!x.range)] 
		y_vertices = candidate.depth*[0,0,1,1,0, 0]
	endif

; =============================
; set up titles, based on the options
; =============================

	if keyword_set(phased) then begin
		if keyword_set(sin) then begin
			title = goodtex(star_dir + ' | A=' + strcompress(/remo, string(format='(F5.3)', sin.a)) +' !CP='+strcompress(/remo, string(format='(F10.5)', sin.period))); + ', HJDo ' + string(sin.hjd0, format='(F9.3)') + ' = ' + date_conv(sin.hjd0+2400000.5d - 7.0/24.0, 'S'))
		endif else begin
			title = goodtex(star_dir + ' | D/\sigma=' + strcompress(/remo, string(format='(F5.1)', transit.depth/transit.depth_uncertainty)) + ', D=' + strcompress(/remo, string(format='(F5.3)', candidate.depth)) +' !CP='+strcompress(/remo, string(format='(F8.5)', candidate.period)) + ', HJDo ' + string(candidate.hjd0, format='(F9.3)') + ' = ' + date_conv(candidate.hjd0+2400000.5d - 7.0/24.0, 'S'))
		endelse
	endif else begin
		if keyword_set(time) then begin
			title = goodtex(star_dir + ' | D/\sigma=' + strcompress(/remo, string(format='(F5.1)', transit.depth/transit.depth_uncertainty)) + ', D=' + strcompress(/remo, string(format='(F5.3)', candidate.depth)) +' !CP='+strcompress(/remo, string(format='(F8.5)', candidate.period)) + ', HJDo ' + string(candidate.hjd0, format='(F9.3)') + ' = ' + date_conv(candidate.hjd0+2400000.5d - 7.0/24.0, 'S'))
		endif else begin
			title = goodtex(star_dir + ' | D/\sigma=' + strcompress(/remo, string(format='(F5.1)', transit.depth/transit.depth_uncertainty)) + ', D=' + strcompress(/remo, string(format='(F5.3)', candidate.depth)) +' !CP='+strcompress(/remo, string(format='(F8.5)', candidate.period)) + ', HJDo ' + string(candidate.hjd0, format='(F9.3)') + ' = ' + date_conv(candidate.hjd0+2400000.5d - 7.0/24.0, 'S'))
		endelse
	endelse
	if keyword_set(box) then begin
		title = goodtex(star_dir + ' | D/\sigma=' + strcompress(/remo, string(format='(F5.1)', box.depth/box.depth_uncertainty)) + ', D=' + strcompress(/remo, string(format='(F5.3)', box.depth)) +' !CP='+strcompress(/remo, string(format='(F8.5)', candidate.period)) + ', HJD ' + string(box.hjd, format='(F9.3)') + ' = ' + date_conv(box.hjd+2400000.5d - mearth_timezone(), 'S')) + ', #' + rw(round((box.hjd - candidate.hjd0)/candidate.period))
	endif
	if keyword_set(anonymous) then begin
		title = str_replace(title, star_dir, 'MEarth candidate')
	endif
	if keyword_set(replacementtitle) then title = replacementtitle

; ======================================
; if /diagnosis is set, set things up to include external parameters
; ======================================

	if keyword_set(diagnosis) then begin
		restore, star_dir + 'raw_ext_var.idl'
		raw_ext_var = ext_var
		restore, star_dir + 'ext_var.idl'
		diagnosis_tags = ['AIRMASS', 'EXTC', 'SEE', 'ELLIPTICITY', 'SKY', 'COMMON_MODE', 'HUMIDITY', 'SKYTEMP', 'RIGHT_XLC', 'LEFT_XLC', 'RIGHT_YLC', 'LEFT_XLC']
	
		n_diagnosis = n_elements(diagnosis_tags)
		ygap=0.004
	endif else begin
		n_diagnosis=0
	endelse

; =========================================
; if /comparisons is set, set things up to include some comparison stars
; =========================================

	if keyword_set(comparisons) then begin
		restore, star_dir + 'comparisons_lc.idl'
		n_comparisons = n_elements(comparisons_lc[0,*]) 
		comp_scatters = fltarr(n_comparisons)
		for i=0, n_comparisons-1 do comp_scatters[i] = stddev(comparisons_lc[*,i].flux)
		comparisons_lc = comparisons_lc[*,sort(comp_scatters)]
		n_comparisons = n_comparisons < 10
		ygap=0.004
	endif else begin
		n_comparisons=0
	endelse

; =========================================
; set up postscript output, if /eps is set; set up xwindow otherwise
; =========================================

	if keyword_set(eps) then begin
		set_plot, 'ps'
		file_mkdir, star_dir + 'plots/'
		filename = star_dir + 'plots/'+strcompress(/rem, n_lc)+'lc'
		if keyword_set(diagnosis) then filename += '_diagnosis'
		if keyword_set(candidate) then filename += '_candidate'
		if ~keyword_set(time) then filename += '_datapoints'
 		if keyword_set(sin) then filename +='_sin'
		if keyword_set(phased) then filename +='_phased'
		if keyword_set(binned) then filename +='_binned'
		if keyword_set(event) then filename += '_' + string(box.hjd, format='(F9.3)') 
		if keyword_set(label) then filename += label
; 		if keyword_set(transit_number) then filename +='_transit'+strcompress(/remo, transit_number)
		filename += '.eps'
		device, filename=filename, /encapsulated, /color, /inches, xsize=9, ysize=6+keyword_set(diagnosis)*7;4*n_lc
		if ~keyword_set(externalformatting) then symsize=.7
		if ~keyword_set(externalformatting) then !p.charsize=0.9
		!x.thick=2
		!y.thick=2
		!p.charthick=2
	endif else begin
		if ~keyword_set(wtitle) then wtitle=star_dir
		screensize = get_screen_size()
		xsize=600
		ysize=150*(n_lc+n_diagnosis+n_comparisons) < screensize[1]*0.3
		if keyword_set(diagnosis) then ysize=150*(n_lc+n_diagnosis+n_comparisons)< screensize[1]
		if keyword_set(event) then begin
; 			ysize = 550
; 			xsize = 400
			ysize = screensize[1]*0.85
			xsize = ysize*3./5.
			if ~keyword_set(externalformatting) then !p.charsize=0.7*ysize/550.0
		endif
		ypos = screensize[1]-ysize
		if screensize[0] gt 1500 then begin
	;			xpos = xsize*1.1
				ypos = screensize[1]-ysize
		endif
		if keyword_set(time) and ~keyword_set(phased) and ~keyword_set(box) then begin
			wtitle += ' + season in time'
	;		xpos = 20
			if screensize[0] gt 1500 then begin
	;			xpos = xsize*1.1
				ypos =screensize[1]-2*ysize
			endif
		endif
		if ~keyword_set(time) and ~keyword_set(phased) and ~keyword_set(box) then begin
			wtitle += ' + season in datapoints'	
		endif
		if keyword_set(phased) then begin
			wtitle += ' + phased'
	;		xpos = 40
			if screensize[0] gt 1500 then begin
				xpos = xsize*1.1
				ypos = screensize[1]-3*ysize
			endif
		endif
		if keyword_set(box) then begin
			wtitle += ' + individual events'
;			xpos = 0

		endif
		if ~keyword_set(externalformatting) then	xplot, !d.window < 30, xsize=xsize, ysize=ysize, title=wtitle, xpos=xpos, ypos=ypos, top=top
		if ~keyword_set(externalformatting) then symsize=1.0
	endelse

	!x.style=3

; ===================================================
; start plotting. set up smultiplot grid, plot (diagnostics), (comparisons), and light curves
; ===================================================

 	n_diagnosis +=1
 	if n_diagnosis +n_comparisons gt 1 then rowhei=[fltarr(n_diagnosis+n_comparisons)+1, fltarr(n_lc)+2] else rowhei=[ fltarr(n_lc)+2]

	colwidths = [12.0,1.0]
	if keyword_set(noleft) then colwidths=[12.0,2]
	smultiplot,/init, [2,n_lc+n_diagnosis+n_comparisons], ygap=ygap, xgap=0, colwidths=colwidths, rowhei=rowhei

	; plot diagnostics
	if keyword_set(diagnosis) then begin
		;!x.charsize=.5
		; loop over diagnostics
		for i=0, n_elements(diagnosis_tags)-1 do begin
			smultiplot
			!y.title = str_replace(diagnosis_tags[i], '_', '!C')
			this = where(strmatch(tag_names(ext_var), diagnosis_tags[i]) gt 0)
			raw_ev = raw_lcs.(0)
			raw_ev.flux = raw_ext_var.(this)
			lc = lcs.(0)
			lc.flux = ext_var.(this)
			!y.range = [min(lc.flux), max(lc.flux)]
			oldxtickunits = !x.tickunits
			!x.tickunits=''
			xtickunits = !x.tickunits
;			if keyword_set(time) then begin
				loadct, 54, file='~/zkb_colors.tbl', /silent
				theta = findgen(21)/20*2*!pi
				usersym, cos(theta), sin(theta)
				; plot raw diagnostics
				if strmatch(diagnosis_tags[i], 'RIGHT_*') eq 1 then begin
					i_wrongmerid = where(ext_var.merid eq 0, n_wrongmerid)
					if n_wrongmerid gt 0 then lc[i_wrongmerid].flux = 0.0/0.0
					i_rawwrongmerid = where(raw_ext_var.merid eq 0, n_rawwrongmerid)
					if n_rawwrongmerid gt 0 then raw_ev[i_rawwrongmerid].flux = 0.0/0.0
				endif

				if strmatch(diagnosis_tags[i], 'LEFT_*') eq 1 then begin
					i_wrongmerid = where(ext_var.merid eq 1, n_wrongmerid)
					if n_wrongmerid gt 0 then lc[i_wrongmerid].flux = 0.0/0.0
					i_rawwrongmerid = where(raw_ext_var.merid eq 1, n_rawwrongmerid)
					if n_rawwrongmerid gt 0 then raw_ev[i_rawwrongmerid].flux = 0.0/0.0
				endif

				if strmatch(diagnosis_tags[i], '*COMMON_MODE*') eq 0 then plot_lc, no_outliers=no_outliers, xaxis=raw_lcs.(0).x, xtickunits=xtickunits, raw_ev, psym=8, symsize=symsize, time=time, /subtle, /noax, hide=keyword_set(no_raw)
				plot_lc, no_outliers=no_outliers, xaxis=lcs.(0).x,xtickunits=xtickunits, lc, symsize=symsize, time=time, nobad=fake, colorbar=0, /justaxes


			;	plot_lc, no_outliers=no_outliers, xaxis=lcs.(0).x, xtickunits=xtickunits, lc, psym=8, symsize=symsize, time=time, /subtle, /noax
;			endif
			i_intransit = where(lc.intransit, n_intransit)
			if n_intransit gt 0 and ~keyword_set(no_intransit) then begin
				plots, lc[i_intransit].x, lc[i_intransit].flux, psym=8, symsize=2*symsize, color=50, thick=3, noclip=0
	;			usersym, cos(theta), sin(theta), /fill
	;			plots, lc[i_intransit].x, lc[i_intransit].flux, psym=8, symsize=2.5, color=255, noclip=0
			endif
			; plot binned diagnostics
			!p.color = 0
			@psym_circle
		;	plot_lc, no_outliers=no_outliers, xaxis=lcs.(0).x,xtickunits=xtickunits, lc, symsize=symsize, time=time, /noax
				for i_seg=0, n_elements(segments_boundaries)-1 do begin
					if i_seg eq 0 then seg_start = 0 else seg_start = segments_boundaries[i_seg-1]
					segment = seg_start + indgen(segments_boundaries[i_seg] - seg_start )
					plot_lc, no_outliers=no_outliers, xaxis=lcs.(0)[segment].x,xtickunits=xtickunits, lc[segment], symsize=symsize, time=time, nobad=fake, colorbar=colorbars[i_seg], /noaxes
				endfor


			if keyword_set(transit) then begin
				vline, transit.hjd0 - transit.duration/2.0 + 2400000.5d, thick=1, color=125
				vline, transit.hjd0 + transit.duration/2.0 + 2400000.5d , thick=1, color=125
			endif
			!p.title=''
			!y.title=''
			!x.tickunits = oldxtickunits
		
			; plot histograms of the binned diagnostics
			smultiplot
			if ~keyword_set(noright) then begin
				old_xrange = !x.range
				bin = (max(!y.range) - min(!y.range))/20.0
				if bin eq 0 then bin = 0.1
				if total(finite(lc.flux)) gt 0 then !x.range=[.7, max(histogram(bin=bin, locations=locations,lc.flux, /nan))]
				!x.style = 7
				!y.style = 5
				loadct, 0, /silent
				if total(finite(lc.flux)) gt 0  then zplothist, lc.flux, /rotate, bin=bin, /log, only=where(lc.okay)
				!x.range = old_xrange
				if keyword_set(transit) then begin
					loadct, 0, /silent
					i_intransit = where(lc.intransit, n_intransit)
					if keyword_set(n_intransit) then begin
						if total(finite(lc[i_intransit].flux)) gt 0 then zplothist, /over, lc[i_intransit].flux, color=25, bin=bin, /rot
					endif
				endif
			endif
		endfor
	endif

	; plot comparisons
; 	if keyword_set(comparisons) then begin
; 		!x.charsize=1
; 		for i=0, n_comparisons-1 do begin
; 			smultiplot
; 			!y.title = strcompress(i)
; 			lc.fluxerr = comparisons_lc[*,i].fluxerr
; 			lc.flux = median_filter(comparisons_lc[*,i].hjd, comparisons_lc[*,i].flux)
; 			!y.range = [1,-1]*1.48*mad(lc.flux)*5;[min(lc.flux), max(lc.flux)]
; 			oldxtickunits = !x.tickunits
; 			!x.tickunits=''
; 			xtickunits = !x.tickunits
; 			!p.color = 0
; 			
; 			@psym_circle
; 			plot_lc, no_outliers=no_outliers, xaxis=xaxis,xtickunits=xtickunits, lc, symsize=symsize, time=time, /noax
; 			if keyword_set(transit) then begin
; 				vline, transit.hjd0 - transit.duration/2.0 + 2400000.5d, thick=1, color=125
; 				vline, transit.hjd0 + transit.duration/2.0 + 2400000.5d , thick=1, color=125
; 			endif
; 			!p.title=''
; 			!y.title=''
; 			!x.tickunits = oldxtickunits
; 			
; 			smultiplot
; 			old_xrange = !x.range
; 			bin = (max(!y.range) - min(!y.range))/20.0
; 			if bin eq 0 then bin = 0.1
; 			!x.range=[.7, max(histogram(bin=bin, locations=locations,lc.flux))]
; 			!x.style = 7
; 			!y.style = 5
; 			loadct, 0, /silent
; 			zplothist, lc.flux, /rotate, bin=bin, /log
; 			!x.range = old_xrange
; 			if keyword_set(transit) then begin
; 				loadct, 0, /silent
; 				i_intransit = where(lc.intransit, n_intransit)
; 				if keyword_set(n_intransit) then begin
; 					zplothist, /over, lc[i_intransit].flux, color=25, bin=bin, /rot
; 				endif
; 			endif
; 		endfor
; 	endif

	; add some spaces before light curves
	if keyword_set(comparisons) or keyword_set(diagnosis) then begin
		smultiplot
		smultiplot
	endif

	; start plotting light curves!
	!y.range=[scale, -scale]
	bin =0.001

	; loop over the light curves
	for i=0, n_lc-1 do begin
		; set up xaxis labels for bottom plot
		if i eq n_lc-1 then begin
			!x.title='Observation Number'
			if keyword_set(time) then begin
			;	!x.title = 'Time'
				!x.title=''
				xtickunits=['Months', 'Years','Numeric']
				if keyword_set(box) then xtickunits='';['Hours',  'Days', 'Months', 'Years']
			endif else begin
				if keyword_set(night) then !x.title = 'Observation Number'
			endelse
			if keyword_set(phased) then begin
				if keyword_set(sin) then !x.title='Time Phased to Sinusoidal Period' else  !x.title='Phased Time from !CMid-Transit (hours)'
				xtickunits=''
				!x.tickunits=xtickunits
				!x.tickname=''
			endif
			if keyword_set(event) then !x.title='Time from Mid-transit (hours)'
			!x.charsize=1

		endif
		if keyword_set(addspace) then !x.title = addspace +!x.title
		if keyword_set(noxtitle) then !x.title=''

		smultiplot, dox=i eq (n_lc-1)
		if keyword_set(noleft) then begin
			!y.title = ' '
			!y.tickname = replicate('   ', 20)
		endif else begin
			!y.title = lc_titles[i]
		endelse
		lc = lcs.(i)
		theta = findgen(21)/20*2*!pi
		usersym, cos(theta), sin(theta)
		; plot raw light curves
		plot_lc, no_outliers=no_outliers, xaxis=raw_lcs.(i).x,raw_lcs.(i), psym=8, symsize=symsize, time=time, /subtle, hide=keyword_set(fake) or keyword_set(binned) or keyword_set(no_raw)
		if keyword_set(noleft) then !y.charsize=1
		xvariable = !x
		yvariable = !y
		i_intransit = where(lcs.(i).intransit, n_intransit)

; 		if keyword_set(box) or keyword_set(phased) then begin
; 			xvert = [-candidate.period/2, -candidate.duration/2, -candidate.duration/2, candidate.duration/2, candidate.duration/2, candidate.period/2]
; 			units = 24
; 	
; ; 			if keyword_set(phased) then begin
; ; 				polyfill, units*candidate.duration/2*[-1,1,1,-1], [(candidate.depth + candidate.depth_uncertainty), (candidate.depth + candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty), (candidate.depth - candidate.depth_uncertainty)], color=200
; ; 				oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth + candidate.depth_uncertainty), color=100, thick=3
; ; 				oplot, units*xvert, [0,0,1,1,0,0]*(candidate.depth - candidate.depth_uncertainty), color=100, thick=3
; ; 			endif else begin
; ; 
; ; 			endelse
; 
; ; 			loadct, 0, /silent
; ; 			offset=0;if keyword_set(phased) then offset=0 else offset = median(target_lc[i_night].flux)
; ; 			oplot, x_vertices, y_vertices+offset, linestyle=2, color=125, thick=2
; 		endif
		loadct, file='~/zkb_colors.tbl', 58, /silent
				hjdsupersampled = generate_highres_sampling(lc, box=box)
				if strmatch(tags_of_lc[i], 'uncorrected', /fold_case) then begin
					model_middle = interpol((inflated_lc.flux - cleaned_lc.flux), lc.hjd, hjdsupersampled)
					model_uncertainty = interpol(uncertainty_overall_model, lc.hjd, hjdsupersampled)
				endif
				if strmatch(tags_of_lc[i], 'variability', /fold_case) then begin
					model_middle =  interpol((variability_lc.flux - cleaned_lc.flux) , lc.hjd, hjdsupersampled)
					model_uncertainty =  interpol(uncertainty_variability_model, lc.hjd, hjdsupersampled)
				endif
				if strmatch(tags_of_lc[i], 'cleaned', /fold_case) then begin
					model_middle = interpol( (cleaned_lc.flux - cleaned_lc.flux) , lc.hjd, hjdsupersampled)
					model_uncertainty =  interpol( (cleaned_lc.flux - cleaned_lc.flux) , lc.hjd, hjdsupersampled)
					if keyword_set(phased) or keyword_set(box) then begin
						if ~keyword_set(offset) then offset = 0
						if keyword_set(phased) then str = 'phased !C'+goodtex('D/\sigma=' + strcompress(/remo, string(format='(F5.1)', candidate.depth/candidate.depth_uncertainty))) else str = 'event #' + rw(round((box.hjd - candidate.hjd0)/candidate.period) - offset) + '!C'+ goodtex('D/\sigma=' + strcompress(/remo, string(format='(F5.1)', box.depth/box.depth_uncertainty)))
						xyouts, 0, !y.range[1], '!C'+str, align=0.5
					endif 

				endif		
				i_superintransit = where_intransit(struct_conv({hjd:hjdsupersampled}), candidate, n_superintransit)
				if n_superintransit gt 0 then begin
					if keyword_set(box) then begin
						model_middle[i_superintransit] += box.depth
						model_uncertainty[i_superintransit] = box.depth_uncertainty
					endif else begin
						model_middle[i_superintransit] += candidate.depth
						model_uncertainty[i_superintransit] = sqrt(candidate.depth_uncertainty^2 + model_uncertainty[i_superintransit]^2)
					endelse
				endif
				
				
;				polyfill, units*box.duration/2*[-1,1,1,-1], [(box.depth + box.depth_uncertainty), (box.depth + box.depth_uncertainty), (box.depth - box.depth_uncertainty), (box.depth - box.depth_uncertainty)], color=200
;				oplot, units*xvert, [0,0,1,1,0,0]*(box.depth + box.depth_uncertainty), color=100, thick=3
;				oplot, units*xvert, [0,0,1,1,0,0]*(box.depth - box.depth_uncertainty), color=100, thick=3
			if keyword_set(phased) then begin
				if keyword_set(sin) then begin
					pad = long((max(hjdsupersampled) - min(hjdsupersampled))/candidate.period) + 1
					phased_time = (hjdsupersampled-sin.hjd0)/sin.period + pad + 0.5
					orbit_number = long(phased_time)
 					xsupersampled = (phased_time - orbit_number - 0.5)*sin.period*24
				endif else begin
					pad = long((max(hjdsupersampled) - min(hjdsupersampled))/candidate.period) + 1
					phased_time = (hjdsupersampled-candidate.hjd0)/candidate.period + pad + 0.5
					orbit_number = long(phased_time)
					xsupersampled = (phased_time - orbit_number - 0.5)*candidate.period*24		
				endelse

			endif else xsupersampled =  interpol(lc.x, lc.hjd, hjdsupersampled)
	
			dt = xsupersampled[1:*] - xsupersampled[0:*]
			gap_definition = 3*median(dt)
			starts_of_gaps = [where(abs(dt) gt gap_definition), n_elements(xsupersampled) -1 ]
			if starts_of_gaps[0] eq -1 then starts_of_gaps = n_elements(xsupersampled)-1
			ends_of_gaps = [0, where(abs(dt) gt gap_definition)+1]
			if ~keyword_set(no_model) then begin
				for j=0, n_elements(starts_of_gaps)-1 do begin
					oneway = xsupersampled[ends_of_gaps[j]:starts_of_gaps[j]]
					top = model_middle[ends_of_gaps[j]:starts_of_gaps[j]] + model_uncertainty[ends_of_gaps[j]:starts_of_gaps[j]]
					bottom =model_middle[ends_of_gaps[j]:starts_of_gaps[j]] - model_uncertainty[ends_of_gaps[j]:starts_of_gaps[j]]
					xvert = [ oneway,  reverse(oneway)];xsupersampled[ends_of_gaps[j]],
					yvert = [top, reverse(bottom) ];model_middle[ends_of_gaps[j]] - model_uncertainty[ends_of_gaps[j]], 
					polyfill, xvert, yvert, color=220, noclip=0
					oplot, oneway, top, color=150, thick=3
					oplot, oneway, bottom, color=150, thick=3
	
				endfor
			endif

		if n_intransit gt 0 and (~keyword_set(binned) or ~(keyword_set(phased) or keyword_set(event))) and ~keyword_set(no_intransit) then begin
; 			if keyword_set(phased) then begin
; 				plots, candidate.duration/2.0*24*[1,1], [1, 0.5]*!y.range[1], thick=1;, color=255
; 				plots, -candidate.duration/2.0*24*[1,1], [1, 0.5]*!y.range[1], thick=1;, color=255
; 			endif; else 
			loadct, /silent, 54, file='~/zkb_colors.tbl'
			plots, lcs.(i)[i_intransit].x, lcs.(i)[i_intransit].flux, psym=8, symsize=2*symsize, color=50, thick=3, noclip=0
;			usersym, cos(theta), sin(theta), /fill
;			plots, lcs.(i)[i_intransit].x, lcs.(i)[i_intransit].flux, psym=8, symsize=2.5, color=255, noclip=0
		endif

		loadct, 0
		if keyword_set(title) and i eq 0 then !p.title=title
		; plot binned light curves

		if n_elements(xtickunits) eq 3 then xtickformat=['', '', 'TRIMLONGDATE']
		plot_lc, no_outliers=no_outliers, xaxis=lcs.(i).x,xtickunits=xtickunits, lcs.(i), symsize=0.001, time=time, nobad=fake, colorbar=0, /justaxes, xtickformat=xtickformat
!p.title=''
		for i_seg=0, n_elements(segments_boundaries)-1 do begin
			if i_seg eq 0 then seg_start = 0 else seg_start = segments_boundaries[i_seg-1]
			segment = seg_start + indgen(segments_boundaries[i_seg] - seg_start)
			plot_lc, no_outliers=no_outliers, xaxis=lcs.(i)[segment].x,xtickunits=xtickunits, lcs.(i)[segment], symsize=symsize*(1.0 - keyword_set(binned)*0.5), time=time, nobad=fake, colorbar=colorbars[i_seg], /noaxes
		endfor

		if keyword_set(binned) then begin
			loadct, 0
			if ~keyword_set(n_bins) then n_bins = 5*candidate.period/candidate.duration
			plot_binned, lcs.(i).x, lcs.(i).flux, n_bins=n_bins, /sem,  psym=8, /overplot, color=180, symsize=0.3, thick=5*keyword_set(eps), /justbins, hatlen=hatlen
		endif 
		this_coordinate_conversion = {x:!x, y:!y, p:!p}
		if n_tags(coordinate_conversions) eq 0 then coordinate_conversions = this_coordinate_conversion else coordinate_conversions = [coordinate_conversions, this_coordinate_conversion]
; 		if ~keyword_set(time) then begin
; 			model = (lcs.(i).flux - interpol(lcs.(n_lc-1).flux, lcs.(n_lc-1).hjd, lcs.(i).hjd)) + candidate.depth*lcs.(i).intransit
; 			loadct, file="~/zkb_colors.tbl", 58
; 			oplot, lcs.(i).x, model, color=100, thick=2
; 		endif
		!p.title=''
		loadct, 43, file='~/zkb_colors.tbl', /silent
		; plot histogram		
		smultiplot
		loadct, 0, /silent
		!y.title=''
		!x.title=''
		old_xrange = !x.range
		old_yrange = !y.range
		!y.range=[scale, -scale]
		!x.range=[.7, max(histogram(bin=bin, locations=locations,lcs.(n_lc-1).flux))]
		!x.style = 7
		!y.style = 5
		if ~keyword_set(noright) then begin

			zplothist, lcs.(i).flux, /rotate, bin=bin, /gauss, /log, only=where(lcs.(i).okay)
			i_intransit = where(lcs.(i).intransit, n_intransit)
			if keyword_set(n_intransit) then begin
				loadct, 0, /silent
				zplothist, /over, lcs.(i)[i_intransit].flux, color=25, bin=bin, /rot
			endif
		endif
		!y.range = old_yrange
		!x.range = old_xrange
	endfor



	smultiplot, /def
	if keyword_set(display) and ~keyword_set(externalformatting) then cleanplot, /silent
	if keyword_set(eps) then begin
		device, /close
		if keyword_set(png) then epstopng, working_dir + filename, dpi=200 else epstopdf, filename
	endif
	!x= xvariable
	!y= yvariable
END


