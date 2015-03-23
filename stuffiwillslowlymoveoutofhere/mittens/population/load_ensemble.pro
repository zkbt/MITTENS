FUNCTION load_ensemble, p,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, suffix, n=n
f = subset_of_stars('cleaned_lc.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n)
f = f[where(file_test(f + '/ext_var.idl'))]
	;skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $

  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  n = n_elements(f)
  s = create_struct('LSPM', 0, {lightcurve}, {external_variable}, 'in_transit', 0B)
  p = replicate({lspm:0, planet_1sigma:0.0, unfiltered_planet_1sigma:0.0, predicted_planet_1sigma:0.0, stellar_radius:0.0, rms:0.0, unfiltered_rms:0.0, predicted_rms:0.0}, n)
  for i=0, n-1 do begin

 	star_dir = f[i];strmid(f[i], 0, strpos(f[i], 'cleaned'))
	;if total(strmatch(skip_list, star_dir)) then continue
	
		print, star_dir
		restore, star_dir + 'cleaned_lc.idl'
		if n_elements(cleaned_lc) gt 5 then begin
		restore, star_dir + 'ext_var.idl'
		;	 restore, star_dir + 'cleaned_lc.idl'
			p[i].unfiltered_rms = stddev(cleaned_lc.flux)
		;	p[i].rms = stddev(cleaned_lc.flux)
			p[i].predicted_rms = mean(cleaned_lc.fluxerr)
		
		lspm_info = get_lspm_info(ls[i])
;		cleaned_lc.flux *=	(lspm_info.radius*109.04501)^2
;		cleaned_lc.fluxerr *=	(lspm_info.radius*109.04501)^2
		;     cleaned_lc.flux *=	(lspm_info.radius*109.04501)^2
		;     cleaned_lc.fluxerr *=	(lspm_info.radius*109.04501)^2
		this = replicate(s, n_elements(cleaned_lc))
		this.lspm = ls[i]
		this.in_transit = in_an_intransit_box

		copy_struct, cleaned_lc, this
		ext_var.left_xlc -=  median(ext_var.left_xlc)
		ext_var.left_ylc -=  median(ext_var.left_ylc)
		ext_var.right_xlc -=  median(ext_var.right_xlc)
		ext_var.right_ylc -=  median(ext_var.right_ylc)
		ext_var.extc -= max(ext_var.extc)
			copy_struct, ext_var, this
			p[i].lspm = ls[i]
		;	   p[i].planet_1sigma = sqrt( stddev(cleaned_lc.flux))
			p[i].unfiltered_planet_1sigma = sqrt(stddev(cleaned_lc.flux))
			p[i].predicted_planet_1sigma = sqrt(mean(cleaned_lc.fluxerr))
			p[i].stellar_radius = lspm_info.radius
		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
	endif
  endfor
  return, cloud
END