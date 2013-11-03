PRO run_vartools
	common this_star
	common mearth_tools
	filename =  'roughly_cleaned_toward_flat_lc.ascii'
	if file_test(star_dir + 'roughly_cleaned_toward_flat_lc.idl') eq 0 then rough_clean
	if file_test(star_dir + 'roughly_cleaned_toward_flat_lc.idl') eq 0 then return
	if is_uptodate(star_dir + filename, star_dir + 'target_lc.idl') then begin
		mprint, skipping_string, 'vartools (probably) already run'
		return
	endif
	restore, star_dir + 'roughly_cleaned_toward_flat_lc.idl'
	if n_elements(roughly_cleaned_lc) lt 30 then return
	lc_to_ascii, roughly_cleaned_lc, star_dir + filename
	r_min = string(format='(F4.2)', lspm_info.radius*0.7)
	r_max = string(format='(F4.2)', lspm_info.radius*1.3)

	n_bls = 10
	outdir =  star_dir() + 'vartools/'
	file_mkdir, outdir
	; see http://www.astro.princeton.edu/~jhartman/vartools.html for usage
	command = "vartools -i " + star_dir + filename + " -ascii -oneline " +$
				" -medianfilter 3.0 "+$
				" -BLS r " + r_min + " " + r_max + " 0.25 10.0 100000 400 -7 "+rw(n_bls)+" " + $
					" 1 " + outdir + " 1 " + outdir + " 0 ";+$
   				;"  ophcurve " + outdir + " -0.1 1.1 0.001"
	print, command
	spawn, command, vartools_output

	if file_test(outdir + filename+'.bls') then begin
		xplot
		!p.multi = [0,1,2]
		readcol, outdir + filename+'.bls', a, b
		plot, a, b
	;	readcol, outdir + filename+'.bls.phcurve', c, d
	
	
		names = rw(stregex(/ex, vartools_output, '[^=]+'))
		values = strmid((stregex(/ex, vartools_output, '=.+')), 1, 1000)
		i_notnull = where(names ne '')
		names = names[i_notnull]
	; 	for i=0, n_elements(names)-1 do begin
	; 		temp = strsplit(names[i], '_')
	; 		if n_elements(temp) gt 1 then names[i] = strmid(names[i], temp[1], temp[2])
	; 	endfor
	;	stop
		values = values[i_notnull]
		s = create_struct(names[0], values[0])
		for j=1, n_elements(names)-1 do s = create_struct(s, names[j], double(values[j]))
	
		bls = replicate({period:0.0d, hjd0:0.0d, duration:0.0, depth:0.0, depth_uncertainty:0.0, n_boxes:0, n_points:0, rescaling:1.0}, n_bls)
	
		i = where(strmatch(names, '*_Period_*') and strmatch(names, '*invtra*') eq 0 )
		bls.period = double(values[i])
		i = where(strmatch(names, '*_Tc_*'))
		bls.hjd0 = double(values[i])
		i = where(strmatch(names, '*_Qtran_*'))
		bls.duration = double(values[i])*bls.period
		i = where(strmatch(names, '*_Depth_*'))
		bls.depth = double(values[i])
		i = where(strmatch(names, '*_SignaltoPinknoise_*'))
		bls.depth_uncertainty = bls.depth/double(values[i])
		i = where(strmatch(names, '*_Ntransits_*'))
		bls.n_boxes = double(values[i])
		i = where(strmatch(names, '*_Npointsintransit_*'))
		bls.n_points = double(values[i])
	
		i_intransit = where_intransit(roughly_cleaned_lc, bls[0], phased_time=phased_time)
		loadct, 39
		plot, phased_time, roughly_cleaned_lc.flux, psym=1
	;	oplot, c*bls[0].period,d, color=250
		for i=0, n_elements(vartools_output)-1 do print, vartools_output[i]
		print_struct, bls
		
		save, filename=star_dir + 'vartools_bls.idl', bls, vartools_output
	endif
END