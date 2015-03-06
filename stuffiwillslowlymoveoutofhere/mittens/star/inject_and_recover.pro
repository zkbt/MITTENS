

PRO inject_and_recover, n

  common this_star
  common mearth_tools

	@constants

	if not keyword_set(n) then n=50000
  folder = 'injection_test/'
;  if is_uptodate(star_dir + folder + 'overestimate.idl', star_dir + 'medianed_lc.idl') then begin
;    mprint, skipping_string, 'sensitivity (over)-estimate is up to date!'
;    return
;  endif
  mprint, doing_string, '(over)-estimating detection efficiency!'
  if file_test(star_dir + 'medianed_lc.idl') eq 0 then begin
    mprint, skipping_string, 'not enough points to make injection worthwhile'
    return
  endif
  restore, star_dir + 'target_lc.idl'
  restore, star_dir + 'medianed_lc.idl'
  lc = medianed_lc
  struct = create_struct({candidate}, 'B', 0.0, 'RADIUS', 0.0)
  struct.fap = 1.0
  injected = replicate(struct, n)
  recovered = replicate(struct, n)
  n_data = n_elements(lc)
  for i=0L, n-1 do begin
    
    copy_struct, generate_fake(), struct
    injected[i] = struct

    a_over_rs = a_over_rs(lspm_info.mass, lspm_info.radius, injected[i].period)
    injected[i].duration = injected[i].period/a_over_rs/!pi*sqrt(1.0 - injected[i].b^2)
    i_int = where_intransit(lc, injected[i], i_oot=i_oot, n_int)
    injected[i].depth = (injected[i].radius*0.00917/lspm_info.radius)^2
    transit = fltarr(n_data)
    injected[i].n_int = n_int
    if n_int gt 0 then transit[i_int] += injected[i].depth
  

    if n_int gt 0 then begin 
      injected[i].chi = total(transit[i_int]/lc[i_int].fluxerr^2)^2/total(1.0/lc[i_int].fluxerr^2)
;      if n_int eq 1 then injected[i].f = 1.0 else begin
;        h = histogram(round(lc[i_int].hjd-0.292), reverse_indices=ri)
;        i_ok = where(h gt 0, n_ok)
;        for ii=0, n_ok-1 do begin
;          j = i_ok[ii]
;          k = i_int[ri[ri[j]:ri[j+1]-1]]
;          injected[i].f = total(lc[k].flux/lc[k].fluxerr^2)^2/total(1.0/lc[k].fluxerr^2)/injected[i].chi > injected[i].f
;        endfor
;      endelse

    endif
    
    ;clean_lightcurve, /injection_test, medianed_lc=medianed_lc, target_lc=target_lc
    recovered[i].period = injected[i].period
    recovered[i].hjd0 = injected[i].hjd0
    recovered[i].duration = injected[i].period/a_over_rs/4.0
    i_int = where_intransit(lc, recovered[i], i_oot=i_oot, n_int)
    recovered[i].n_int = n_int
    if n_int gt 0 then begin 
;      injected_lc = target_lc
;      injected_lc.flux += transit  
;      clean_lightcurve, medianed_lc=medianed_lc, target_lc=injected_lc, /injection_test
;      transit = medianed_lc.flux
      recovered[i].chi = total(transit[i_int]/medianed_lc[i_int].fluxerr^2)^2/total(1.0/medianed_lc[i_int].fluxerr^2)
      recovered[i].depth = total(transit[i_int]/medianed_lc[i_int].fluxerr^2)/total(1.0/medianed_lc[i_int].fluxerr^2)
      recovered[i].radius = sqrt(recovered[i].depth)*lspm_info.radius/0.00917
;      if n_int eq 1 then recovered[i].f = 1.0 else begin
;        h = histogram(round(lc[i_int].hjd-0.292), reverse_indices=ri)
;        i_ok = where(h gt 0, n_ok)
;        for ii=0, n_ok-1 do begin
;          j = i_ok[ii]
;          k = i_int[ri[ri[j]:ri[j+1]-1]]
;          recovered[i].f = total(lc[k].flux/lc[k].fluxerr^2)^2/total(1.0/lc[k].fluxerr^2)/recovered[i].chi > recovered[i].f
;        endfor
;      endelse
    endif

  endfor
   file_mkdir, star_dir + folder
   save, filename=star_dir + folder + 'overestimate.idl', injected, recovered, n_data
 
  
 
 
  
;
;		fake_dir = star_dir + 'fakes_b/'
;		if file_test(fake_dir) eq 0 then file_mkdir, fake_dir
;		old_files = file_search(fake_dir + '*fake.idl')
;		if old_files[0] ne '' then start = max(fix(stregex(/extract, stregex(/extract, old_files, '[0-9]+_'), '[0-9]+'))) + 1 else start = 0
;		printl
;		print, '   running filtering test on ', fake_dir
;		printl
;		for i=0, n-1 do begin
;			prefix = 'fakes_b/'+string(format='(I04)', i+start)+'_'	
;			fake = generate_fake()
;			target_lc = orig_target_lc	
;			a_over_rs = 4.2096611/lspm_info.radius*lspm_info.mass^(1.0/3.0)*fake.period^(2.0/3.0)
;			inc = acos(fake.b/a_over_rs)
;			transit = -2.5*alog10(zeroeccmodel(medianed_lc.hjd,fake.hjd0,fake.period,lspm_info.mass,lspm_info.radius,fake.radius*r_earth/r_sun,inc,0.0,0.2,0.6))
;			in_transit = where(transit ne 0, n_int)
;			fake.n_int = n_int
;			target_lc.flux += transit
;			save, filename=star_dir + prefix + 'target_lc.idl', target_lc
;
;			; could speed up by properly treating lightcurves w/out transits!			
;			uberfilter_lightcurve, star_dir=star_dir, prefix=prefix, /no_plot
;
;			restore, star_dir + prefix + 'medianed_lc.idl'
;
;			; plot!
;			erase
;			scale = 1.1*(max(abs(orig_target_lc.flux))  < 5*1.48*mad(orig_target_lc.flux) < 10*1.48*mad(orig_medianed_lc.flux))
;			scale = scale > max(abs(transit)*1.1)
;			!y.range = [scale, -scale]
;			result = create_struct('ORIGINAL', orig_target_lc.flux, 'ORIGINAL_FILTERED', orig_medianed_lc.flux, 'FAKE', target_lc.flux, 'FAKE_FILTERED', medianed_lc.flux, 'DIFFERENCE', medianed_lc.flux - orig_medianed_lc.flux, 'MODEL', transit)
;			plot_struct, result, xs=7, ys=7
;			!y.range=0
;			
;			if n_int gt 0 then begin
;				filtered = struct_conv(result)
;				filtered = filtered[in_transit]
;				save, filename=star_dir + prefix + 'filtered.idl', filtered, fake
;			endif
;			save, filename=star_dir + prefix + 'fake.idl', fake
;			print, i, ' out of ', n,  ' tests complete on '+ star_dir
;		endfor
;		f = file_search(fake_dir + '*filtered.idl')
;		if n_elements(f) gt 0 then begin
;			for i=0, n_elements(f)-1 do begin
;				restore, f[i]
;				if n_elements(obs) eq 0 then begin 
;					obs = filtered 
;					j = intarr(n_elements(filtered)) + i
;					fakes = fake
;				endif else begin
;					obs=[obs,filtered]
;					j = [j, intarr(n_elements(filtered)) + i]
;					fakes = [fakes,fake]
;				endelse
;			endfor
;			set_plot, 'ps'
;			device, filename=star_dir + 'filter_suppression.eps', /encapsulated, xsize=7.5, ysize=4, /inches
;			!p.charsize=1
;			!p.multi=[0,2,1]
;			plot, obs.model, obs.fake_filtered, xtitle='injected[i] (mag.)', ytitle='Filtered (mag.)', psym=1
;			oplot, linestyle=1, [0,1],[0,1]
;			plot, obs.model, obs.difference, xtitle='injected[i] (mag.)', ytitle='Difference Post-filtering (mag.)', psym=1
;			oplot, linestyle=1, [0,1],[0,1]
;		
;
;			device, /close
;			set_plot, 'x'
;		endif
;	endif
;
;
;; 		!p.multi=[0,1,3]
;; 		@psym_circle
;; 		@make_plots_thick
;; 		xplot
;; 		loadct, 39
;; 		plot, medianed_lc.flux, psym=8, yrange=[max(medianed_lc.flux), min(medianed_lc.flux)], xstyle=3
;; 	
;; 		basic_bls = one_star_bls(medianed_lc, lspm_info, star_dir, /no_plot)
;; 		!p.multi=[0,1,3]
;; 		scale = 1.1*(max(abs(medianed_lc.flux)) < 0.1 < 5*1.48*mad(medianed_lc.flux))
;; 		yr = [scale, -scale]
;; 		for i=0, n-1 do begin
;; 			t = systime(/seconds)
;; 			n_int = uint(total(transit ne 0))
;; 			fakes[i].n_int = n_int
;; 
;; 			print, 'fake #', i, '      with ', n_int, ' points in transit'
;; 			print_struct, fakes[i]
;; 	
;; 			if n_int ge 1 then begin
;; 				in_transit = where(transit ne 0)
;; 				simulated_lc.flux = medianed_lc.flux + transit
;; 				plot, simulated_lc.flux, psym=3, yrange=[scale, -scale], xstyle=3, title=star_dir
;; 				plots, in_transit, simulated_lc[in_transit].flux, psym=8, color=250
;; 				temp_bls = one_star_bls(simulated_lc, lspm_info, star_dir, /no_plot)
;; 			endif else temp_bls = basic_bls
;; 			if n_elements(big_bls) eq 0 then big_bls = temp_bls else big_bls = [[[big_bls]],[[temp_bls]]]
;; 			print_struct, temp_bls[0,0]
;; 			print, '     completed in ', systime(/seconds) - t, ' seconds'
;; 			print, ''
;; 	
;; 	
;; 		endfor
;; 		result = file_search(star_dir + 'fakes.idl')
;; 		if result ne '' then begin
;; 			new_fakes = fakes
;; 			new_big_bls = big_bls
;; 			restore, star_dir+ 'fakes.idl'
;; 			fakes = [fakes, new_fakes]
;; 			big_bls = [[[big_bls]],[[new_big_bls]]]
;; 		endif
;; 		save, fakes, big_bls, filename=star_dir + 'fakes.idl'
;; 	endif
END