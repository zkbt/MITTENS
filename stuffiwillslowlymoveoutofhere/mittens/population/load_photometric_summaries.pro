FUNCTION load_photometric_summaries,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n, clean=clean, unknown=unknown
f = subset_of_stars('cleaned_lc.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n); else f = subset_of_stars('target_lc.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n)
f = f[where(file_test(f + '/ext_var.idl'))]
	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $
	if keyword_set(unknown) then begin
		ls =  long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
		i_unknown = where(ls ne 1186 and ls ne 3512 and ls ne 3229 and ls ne 1803, n)
		if n gt 0 then f = f[i_unknown] else stop
	endif

  ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
  ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  n = n_elements(f)
  s = create_struct('LSPM', 0, {lightcurve}, {external_variable}, 'in_transit', 0B)
  p = replicate({lspm:0, planet_1sigma:0.0, unfiltered_planet_1sigma:0.0, predicted_planet_1sigma:0.0, info:get_lspm_info(0), rms:0.0, unfiltered_rms:0.0, predicted_rms:0.0, star_dir:''}, n)
@planet_constants
  for i=0, n-1 do begin

 	star_dir = f[i]
	if total(strmatch(skip_list, star_dir)) then continue
	
		print, star_dir
		restore, star_dir + 'cleaned_lc.idl'
		i_ok = where(cleaned_lc.okay and in_an_intransit_box eq 0, n)
		if keyword_set(clean) then begin
			if n eq 0 then continue
			lc = cleaned_lc[i_ok]
		endif else begin
			restore, star_dir + 'target_lc.idl'
			lc = target_lc
		endelse

		if n_elements(lc) gt 5 then begin
			p[i].unfiltered_rms = 1.48*mad(lc.flux)
			p[i].rms = 1.48*mad(cleaned_lc[i_ok].flux)
			p[i].predicted_rms = mean(lc.fluxerr)
			
			
			p[i].info = get_lspm_info(fix(ls[i]))
			p[i].lspm = ls[i]
	
			p[i].unfiltered_planet_1sigma = sqrt(1.48*mad(lc.flux))*p[i].info.radius*r_sun/r_earth
			p[i].predicted_planet_1sigma = sqrt(mean(lc.fluxerr))*p[i].info.radius*r_sun/r_earth
			p[i].planet_1sigma = sqrt(1.48*mad(cleaned_lc[i_ok].flux))*p[i].info.radius*r_sun/r_earth
			p[i].star_dir = star_dir
		endif
  	endfor
 	return, p
END