PRO plot_lightcurves, n_lc, time=time, night=night, transit=transit, eps=eps, phased=phased, candidate=candidate, fixed=fixed, wtitle=wtitle, lc=lc, sin=sin, number=transit_number, diagnosis=diagnosis, comparisons=comparisons, xrange=xrange, pdf=pdf

cleanplot, /silent
!x.margin=[20,10]
  common this_star
  common mearth_tools
    bin=0.001
  title=star_dir
  if file_test(star_dir + 'superfit.idl') eq 0 then return
  restore, star_dir + 'raw_target_lc.idl'
  raw = target_lc
  restore, star_dir + 'target_lc.idl'
if keyword_set(pdf) then begin
	restore, star_dir + 'cleaned_lc.idl'
	medianed_lc = cleaned_lc
	restore, star_dir + 'variability_lc.idl'
	decorrelated_lc = variability_lc
endif else if file_test(star_dir + 'medianed_lc.idl') then begin
  restore, star_dir + 'superfit.idl'
  restore, star_dir + 'decorrelated_lc.idl'
  restore, star_dir + 'medianed_lc.idl'
endif
   if keyword_set(lc) then scale=5*mad(lc.flux)
 
  !y.ticklen = 0.01
  if not keyword_set(n_lc) then n_lc = 3
  
  ; allow fake light curves to be plotted
  if keyword_set(lc) and n_lc eq 1 then medianed_lc = lc

  lc = target_lc
  if keyword_set(transit) then begin
    night = transit.hjd0;round(transit.hjd0-0.292);
    time = 1
  endif
  
  if keyword_set(time) then begin
    xaxis = lc.hjd + 2400000.5d
    xtickunits='Time'
    !x.charsize=0.0001
	if keyword_set(xrange) then !x.range = xrange+2400000.5d else    !x.range =[min(raw.hjd - 0.5/24.0), max(raw.hjd + 0.5/24.0)] + 2400000.5d
  endif else begin
    xaxis = indgen(n_elements(lc.flux))
  endelse
  
  if keyword_set(phased) then begin
  
    if keyword_set(sin) then begin
      pad = long((max(lc.hjd) - min(lc.hjd))/sin.period) +1
      phased_time = (lc.hjd-sin.hjd0)/sin.period + pad + 0.5
      orbit_number = long(phased_time)
      xaxis = (phased_time - orbit_number - 0.5)*sin.period
      
     
      rawpad = long((max(raw.hjd) - min(raw.hjd))/sin.period) +1
      rawphased_time = (raw.hjd-sin.hjd0)/sin.period + rawpad + 0.5
      raworbit_number = long(rawphased_time)
      rawxaxis = (rawphased_time - raworbit_number - 0.5)*sin.period
      !x.range = [-0.5, 0.5]*sin.period
    endif else begin
    
          pad = long((max(lc.hjd) - min(lc.hjd))/candidate.period) +1
      phased_time = (lc.hjd-candidate.hjd0)/candidate.period + pad + 0.5
      orbit_number = long(phased_time)
      xaxis = (phased_time - orbit_number - 0.5)*candidate.period
      
      rawpad = long((max(raw.hjd) - min(raw.hjd))/candidate.period) +1
      rawphased_time = (raw.hjd-candidate.hjd0)/candidate.period + rawpad + 0.5
      raworbit_number = long(rawphased_time)
      rawxaxis = (rawphased_time - raworbit_number - 0.5)*candidate.period
         !x.range = [-0.5, 0.5]*candidate.duration*20
    i_intransit = where(abs(xaxis) lt candidate.duration/2, n_intransit)
    transit = {hjd0:0.0, duration:candidate.duration, depth:candidate.depth}
    title = goodtex(star_dir + ' | P='+strcompress(/remo, string(format='(F8.5)', candidate.period)) + ', \Delta\chi^2=' + strcompress(/remo, string(format='(F5.1)', candidate.chi)) + ', D=' + strcompress(/remo, string(format='(F5.3)', candidate.depth))+ ', FAP='+string(format='(F6.4)', candidate.FAP) )
    if keyword_set(fixed) then title += ' | HJDo ' + string(candidate.hjd0, format='(F9.3)') + ' = ' + date_conv(candidate.hjd0+2400000.5d - 7.0/24.0, 'S')
      
      
    endelse
    xtickunits = ''
    
   endif
  
  if keyword_set(transit) then begin
        if not keyword_set(candidate) then i_intransit = where_intransit(lc, transit, n_intransit)
  
      if keyword_set(phased) then begin
        x_vertices = [min(!x.range), transit.hjd0 - transit.duration/2.0, transit.hjd0 - transit.duration/2.0, transit.hjd0 + transit.duration/2.0, transit.hjd0 + transit.duration/2.0, max(!x.range)] 
      endif else begin
          x_vertices = [min(lc.hjd), transit.hjd0 - transit.duration/2.0, transit.hjd0 - transit.duration/2.0, transit.hjd0 + transit.duration/2.0, transit.hjd0 + transit.duration/2.0, max(lc.hjd)] + 2400000.5d
          weightedsum = total(medianed_lc[i_intransit].flux/medianed_lc[i_intransit].fluxerr^2, /double)
          transit.deltachi = weightedsum*transit.depth

        title = goodtex(star_dir + ' | \Delta\chi^2=' + strcompress(/remo, string(format='(F5.1)', transit.deltachi)) + ', D=' + strcompress(/remo, string(format='(F5.3)', transit.depth)) )
        title += ' | HJDo ' + string(transit.hjd0, format='(F9.3)') + ' = ' + date_conv(transit.hjd0+2400000.5d - 7.0/24.0, 'S')
      endelse
      y_vertices = transit.depth*[0,0,1,1,0, 0]
    endif

  
  if keyword_set(night) then begin
  ; GOING TO SCREW UP PLOTTING INDIVIDUAL NIGHTS WITHOUT TRANSITS!
    i_rawnight = where(abs(raw.hjd - transit.hjd0) lt 8.0/24.0, n_rawnight)
    i_night = where(abs(target_lc.hjd - transit.hjd0) lt 8.0/24.0, n_night)
    if n_rawnight gt 0 then begin
      if keyword_set(time) then begin
      !x.range = transit.hjd0 + 2400000.5d + [-5, 5]/24.0
       ; !x.range =[night+0.292 - 0.5, night+0.292+0.5]+2400000.5d;[min(raw[i_rawnight].hjd - 0.5/24.0), max(raw[i_rawnight].hjd + 0.5/24.0)] + 2400000.5d 
        xtickunits='Hours'
      endif else begin
        !x.range=[min(i_night), max(i_night)]
      endelse
    endif else return
  endif  
 
    ygap = 0.02
  
    if keyword_set(diagnosis) then begin
    restore, star_dir + 'raw_ext_var.idl'
    raw_ext_var = ext_var
    restore, star_dir + 'ext_var.idl'
    diagnosis_tags = ['AIRMASS', 'EXTC', 'SEE', 'ELLIPTICITY', 'SKY', 'COMMON_MODE', 'MERID']
    
    n_diagnosis = n_elements(diagnosis_tags)
    ygap=0.004
  endif else begin
    n_diagnosis=0
  endelse

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

  
  if keyword_set(eps) then begin
    set_plot, 'ps'
    file_mkdir, star_dir + 'plots/'
    filename = star_dir + 'plots/'+strcompress(/rem, n_lc)+'lc'
    if keyword_set(candidate) then filename += '_candidate'
    if keyword_set(sin) then filename +='_sin'
    if keyword_set(phased) then filename +='_phased'
    if keyword_set(transit_number) then filename +='_transit'+strcompress(/remo, transit_number)
    filename += '.eps'
    device, filename=filename, /encapsulated, /color, /inches, xsize=10, ysize=2*n_lc
 ;   title=''
      if keyword_set(sin) then       title=star_dir
    
    symsize=.6
    !p.charsize=0.7
    !x.thick=2
    !y.thick=2
    !p.charthick=2
    
  endif else begin
    if not keyword_set(wtitle) then wtitle=star_dir + ' + lightcurve'
    xplot, !d.window < 30, xsize=1000, ysize=200*(n_lc+n_diagnosis+n_comparisons) < 750, title=wtitle
    symsize=1.0
  endelse
  
  loadct, 39, /silent
  if not keyword_set(scale) then scale = 5*1.48*mad(target_lc.flux) ;< max(abs(superfit.lc.flux)) ;< 0.1
  if keyword_set(transit) then scale = scale > transit.depth*1.5

 n_diagnosis +=1
 if n_diagnosis +n_comparisons gt 1  then rowhei=[fltarr(n_diagnosis+n_comparisons)+1, fltarr(n_lc)+2] else rowhei=[ fltarr(n_lc)+2]
  smultiplot,  /init, [2,n_lc+n_diagnosis+n_comparisons], ygap=ygap, xgap=0, colwidths=[12.0,1.0], rowhei=rowhei
  
  
  if keyword_set(diagnosis) then begin
    !x.charsize=1
    for i=0, n_elements(diagnosis_tags)-1 do begin
        smultiplot
        !y.title = diagnosis_tags[i]
        this = where(strmatch(tag_names(ext_var), diagnosis_tags[i]) gt 0)
        raw_ev = raw
        raw_ev.flux = raw_ext_var.(this)
        lc.flux = ext_var.(this)
                    !y.range = [min(lc.flux), max(lc.flux)]
                    oldxtickunits = !x.tickunits
        !x.tickunits=''
        xtickunits = !x.tickunits
        if keyword_set(time) then begin
          loadct, 54, file='~/zkb_colors.tbl', /silent
            theta = findgen(21)/20*2*!pi
            usersym, cos(theta), sin(theta)
            if strmatch(diagnosis_tags[i], '*COMMON_MODE*') eq 0 then plot_lc, xaxis=rawxaxis, xtickunits=xtickunits, raw_ev, psym=8, symsize=symsize, time=time, /subtle, /noax
        endif

        !p.color = 0
    
        @psym_circle
        plot_lc, xaxis=xaxis,  xtickunits=xtickunits, lc, symsize=symsize, time=time, /noax
	if keyword_set(transit) then begin
		vline, transit.hjd0 - transit.duration/2.0 + 2400000.5d, thick=1, color=125
		vline, transit.hjd0 + transit.duration/2.0 + 2400000.5d , thick=1, color=125
	endif
        !p.title=''
        !y.title=''
                !x.tickunits = oldxtickunits
        
        smultiplot
        old_xrange = !x.range
        bin = (max(!y.range) - min(!y.range))/20.0
        if bin eq 0 then bin = 0.1
        !x.range=[.7, max(histogram(bin=bin, locations=locations,  lc.flux))]
        !x.style = 7
        !y.style = 5
	loadct, 0, /silent
          zplothist, lc.flux, /rotate, bin=bin, /log
          !x.range = old_xrange        
        if keyword_set(transit) then begin
          loadct, 0, /silent
          if keyword_set(n_intransit) then begin
            zplothist, /over, lc[i_intransit].flux, color=25, bin=bin, /rot
          endif
        endif
        
        
      endfor

  endif
  
; COMPARSIONS!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
if keyword_set(comparisons) then begin
    !x.charsize=1
    for i=0, n_comparisons-1 do begin
        smultiplot
        !y.title = strcompress(i)
	lc.fluxerr = comparisons_lc[*,i].fluxerr
        lc.flux = median_filter(comparisons_lc[*,i].hjd, comparisons_lc[*,i].flux)
        !y.range = [1,-1]*1.48*mad(lc.flux)*5;[min(lc.flux), max(lc.flux)]
        oldxtickunits = !x.tickunits
        !x.tickunits=''
        xtickunits = !x.tickunits
        !p.color = 0
    
        @psym_circle
        plot_lc, xaxis=xaxis,  xtickunits=xtickunits, lc, symsize=symsize, time=time, /noax
	if keyword_set(transit) then begin
		vline, transit.hjd0 - transit.duration/2.0 + 2400000.5d, thick=1, color=125
		vline, transit.hjd0 + transit.duration/2.0 + 2400000.5d , thick=1, color=125
	endif
        !p.title=''
        !y.title=''
                !x.tickunits = oldxtickunits
        
        smultiplot
        old_xrange = !x.range
        bin = (max(!y.range) - min(!y.range))/20.0
        if bin eq 0 then bin = 0.1
        !x.range=[.7, max(histogram(bin=bin, locations=locations,  lc.flux))]
        !x.style = 7
        !y.style = 5
	loadct, 0, /silent
          zplothist, lc.flux, /rotate, bin=bin, /log
          !x.range = old_xrange        
        if keyword_set(transit) then begin
          loadct, 0, /silent
          if keyword_set(n_intransit) then begin
            zplothist, /over, lc[i_intransit].flux, color=25, bin=bin, /rot
          endif
        endif
        
        
      endfor

    
  endif

if keyword_set(comparisons) or keyword_set(diagnosis) then begin
    smultiplot
    smultiplot
endif




    !y.range=[scale, -scale]
  
  bin =0.001
  if n_lc ge 2 then begin
    smultiplot
  
    !y.title = 'Uncorrected!C(mag.)'
    lc = target_lc
    theta = findgen(21)/20*2*!pi
    usersym, cos(theta), sin(theta)
    if keyword_set(time) then plot_lc, xaxis=rawxaxis,  raw, psym=8, symsize=symsize, time=time, /subtle
    if keyword_set(transit) then begin
      loadct, 0, /silent
      if keyword_set(phased) then offset=0 else offset = median(target_lc[i_night].flux)
      oplot, x_vertices, y_vertices+offset, linestyle=2, color=125
    endif
    if keyword_set(sin) then begin
  ;    restore, 'cm.idl'
   ;   i_cmcoef = where(strmatch(superfit.fit.name, 'COMMON_MODE'))
 ; stop 
  ;    oplot, lc.hjd +2400000.5d, superfit.decorrelation+sin.a*sin(2*!pi*(lc.hjd- sin.hjd0)/sin.period)+sin.constant
    endif
    if keyword_set(title) and n_lc ge 2 then !p.title=title
    plot_lc, xaxis=xaxis,  xtickunits=xtickunits, lc, symsize=symsize, time=time
    !p.title=''
    loadct, 43, file='~/zkb_colors.tbl', /silent
    
        smultiplot
        loadct, 0, /silent
      !y.title=''
  !x.title=''
  old_xrange = !x.range
  old_yrange = !y.range
  !y.range=[scale, -scale]
  !x.range=[.7, max(histogram(bin=bin, locations=locations,  medianed_lc.flux))]
  !x.style = 7
  !y.style = 5
    zplothist, target_lc.flux, /rotate, bin=bin, /gauss, /log
      if keyword_set(n_intransit) then begin
	loadct, 0, /silent
        zplothist, /over, target_lc[i_intransit].flux, color=25, bin=bin, /rot
      endif
    !y.range = old_yrange
    !x.range = old_xrange
  endif
  if n_lc ge 3 then begin
    smultiplot
    !y.title = 'Stellar Variability!C(mag.)'
    lc = decorrelated_lc
    if keyword_set(time) then begin
      loadct, 54, file='~/zkb_colors.tbl', /silent
      decorrelated_raw = raw
      decorrelated_raw.flux += zinterpol(decorrelated_lc.flux - target_lc.flux, target_lc.hjd, raw.hjd)
        theta = findgen(21)/20*2*!pi
    usersym, cos(theta), sin(theta)
      plot_lc, xaxis=rawxaxis, xtickunits=xtickunits, decorrelated_raw, psym=8, symsize=symsize, time=time, /subtle

    endif
    if keyword_set(transit) then begin
      loadct, 0, /silent
      if keyword_set(phased) then offset=0 else offset = median(decorrelated_lc[i_night].flux)
      oplot, x_vertices, y_vertices+offset, linestyle=2, color=125
      
          endif
  
    loadct, file="~/zkb_colors.tbl", 54, /silent 
    !p.color = 200
   ; oploterr, xaxis, superfit.variability, superfit.variability_uncertainty, 3
    !p.color=0
      @psym_circle
    
    plot_lc, xaxis=xaxis,  xtickunits=xtickunits, lc, symsize=symsize, time=time
    
          if keyword_set(sin) then begin
            loadct, 54, file='~/zkb_colors.tbl', /silent
      
                if keyword_set(phased) then begin
                  sin_hjd_phased = dindgen(1000)/1000*sin.period - sin.period/2.0
                  oplot, sin_hjd_phased, sin.a*sin(2*!pi*(sin_hjd_phased)/sin.period)+sin.constant, thick=5
                endif else begin
                                sin_hjd = dindgen(1000)/1000*(max(raw.hjd) - min(raw.hjd))+min(raw.hjd)
                
                    oplot, sin_hjd+2400000.5d, sin.a*sin(2*!pi*(sin_hjd- sin.hjd0)/sin.period)+sin.constant, thick=6
                endelse
                
                    
                xyouts, mean(!x.range),  !y.range[1], '!Cperiod = '+strcompress(/remo, string(sin.period, format='(F7.2)')) + ' days, mass = '+string(lspm_info.mass, format='(F4.2)') + ' solar', charthick=5, alignment=0.5
 
      endif
          smultiplot
        loadct, 0, /silent
  !y.title=''
  !x.title=''
  !y.range=[scale, -scale]
  !x.range=[.7, max(histogram(bin=bin, locations=locations,  medianed_lc.flux))]
  !x.style = 7
  !y.style = 5
    zplothist, decorrelated_lc.flux, /rotate, bin=bin, /gauss, /log
      if keyword_set(n_intransit) then begin
	loadct, 0, /silent

        zplothist, /over, decorrelated_lc[i_intransit].flux, color=25, bin=bin, /rot
      endif
        !y.range = old_yrange
    !x.range = old_xrange
    ;oplot, xtickunits=xtickunits,  xaxis, superfit.variability, color=250
  endif

  if n_lc ge 1 then begin
    !x.charsize=1
    smultiplot
    !y.title = 'Residuals!C(mag.)'

    lc = medianed_lc
    if keyword_set(time) then begin
      loadct, 54, file='~/zkb_colors.tbl', /silent
      medianed_raw = raw
      medianed_raw.flux = raw.flux + zinterpol(medianed_lc.flux - target_lc.flux, target_lc.hjd, raw.hjd)
        theta = findgen(21)/20*2*!pi
    usersym, cos(theta), sin(theta)
      plot_lc, xaxis=rawxaxis, xtickunits=xtickunits, medianed_raw, psym=8, symsize=symsize, time=time, /subtle
    endif
    if keyword_set(transit) then begin
      loadct, 0, /silent
      oplot, x_vertices, y_vertices, linestyle=2, color=125
    endif
    loadct, 54, file='~/zkb_colors.tbl', /silent
    !p.color=150
  
 ;   plot, xtickunits=xtickunits,  xaxis, lc.flux, xstyle=7, ystyle=5, /nodata
      loadct, file="~/zkb_colors.tbl", 54, /silent 
    !p.color = 200
  ;  oploterr, xaxis, fltarr(n_elements(superfit.variability)), superfit.variability_uncertainty,3
    !p.color = 0
    !x.title='Observation Number'
    if keyword_set(time) then begin
      !x.title = 'Time (days)'
      if keyword_set(night) then begin
	 !x.title = 'Time (hours)'
	xtickunits='Hours'
	endif
    endif else begin
      if keyword_set(night) then !x.title = 'Observation Number'
    endelse
    if keyword_set(phased) then begin
	!x.title='Phased Time (days)'
	xtickunits=''
	!x.tickunits=xtickunits
	!x.tickname=''

endif
    @psym_circle
    if keyword_set(title) and n_lc eq 1 then !p.title=title
    plot_lc, xaxis=xaxis,   lc, symsize=symsize, time=time, xtickunits=xtickunits
    !p.title=''
        smultiplot
        loadct, 0, /silent
          !y.title=''
  !x.title=''
  
  !y.range=[scale, -scale]
  !x.range=[.7, max(histogram(bin=bin, locations=locations,  medianed_lc.flux))]
  !x.style = 7
  !y.style = 5
    zplothist, medianed_lc.flux, /rotate, bin=bin, /gauss, /log
        loadct, 39, /silent
    if keyword_set(transit) then begin
      ; change this!
      loadct, 0, /silent
      if keyword_set(n_intransit) then begin
        zplothist, /over, medianed_lc[i_intransit].flux, color=25, bin=bin, /rot
;       y = [medianed_lc[i_intransit].flux, medianed_lc[i_intransit].flux]
      endif
        ;   zplothist, /over, medianed_lc[transit.i_start:transit.i_stop].flux, color=25, bin=bin  , /rot
;          y = [medianed_lc[transit.i_start:transit.i_stop].flux, medianed_lc[transit.i_start:transit.i_stop].flux]
;      h = histogram(bin=bin, locations=locations,  min=!y.range[1], max=!y.range[0], y)
;      oplot, h/2.0, locations, color=250
    endif
  endif




  

  
  
  smultiplot,   /def
  if keyword_set(display) then cleanplot, /silent
  if keyword_set(eps) then begin
    device, /close
    epstopdf, filename
  endif
END

  
