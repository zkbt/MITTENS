FUNCTION load_obs_summaries,  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n, clean=clean, unknown=unknown
	f = subset_of_stars('raw_target_lc.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range,  n=n)
	xplot, xsize=700, ysize=300
	if keyword_set(unknown) then begin
		ls =  long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
		i_unknown = where(ls ne 1186 and ls ne 3512 and ls ne 3229 and ls ne 1803, n)
		if n gt 0 then f = f[i_unknown] else stop
	endif

	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))	
	ye = long(stregex(/ext, stregex(/ext, f, 'ye[0-9]+'), '[0-9]+'))
  	te = long(stregex(/ext, stregex(/ext, f, 'te[0-9]+'), '[0-9]+'))
  	n = n_elements(f)

  	obs_summary = replicate({lspm:0, year:0, tel:0, astonly:0B, n_exposures:0, n_goodexposures:0, n_goodpointings:0, nmeas:0, exptime:0.0, nexp_per_pointing:0, medflux:0.0, ra:0.0, dec:0.0}, n)
	obs_summary.lspm = ls
	obs_summary.year = ye
	obs_summary.tel = te
  	for i=0, n-1 do begin

		star_dir = f[i]
		print, star_dir
		restore, star_dir + 'raw_target_lc.idl'
		raw = target_lc
		obs_summary[i].n_exposures = n_elements(raw)
		obs_summary[i].n_goodexposures = fix(total(raw.okay ne 0))
		restore, star_dir + 'jmi_file_prefix.idl'
		if file_test(star_dir+ 'target_lc.idl') then begin
			restore, star_dir + 'target_lc.idl'
			weeded = target_lc
	;		plot, raw.hjd, raw.flux, psym=3, xs=3, yr=[0.02, -0.02]
	;		if n_elements(weeded) gt 1 then oplot, weeded.hjd, weeded.flux, psym=1
			obs_summary[i].n_goodpointings = fix(total(weeded.okay ne 0))
		endif
		if keyword_set(original) then begin
			h = headfits(jmi_file_prefix + '_lc.fits', ext=1)
			obs_summary[i].nmeas = sxpar(h, 'NMEAS')
			obs_summary[i].astonly = sxpar(h, 'ASTONLY')
			obs_summary[i].exptime = median(sxpar(h, 'TEXP*'))
			obs_summary[i].nexp_per_pointing = (sxpar(h, 'NEXP'))
		endif else begin
			restore, star_dir + 'raw_ext_var.idl'
			obs_summary[i].nmeas =obs_summary[i].n_exposures; sxpar(h, 'NMEAS')
			obs_summary[i].astonly = 0; sxpar(h, 'ASTONLY')
			if n_elements(ext_var) EQ 1 then obs_summary[i].exptime = (ext_var.exptime) else obs_summary[i].exptime = median(ext_var.exptime)
			if n_elements(ext_var) EQ 1 then obs_summary[i].nexp_per_pointing = (ext_var.nexp) > 1 else obs_summary[i].nexp_per_pointing = median(ext_var.nexp) > 1;(sxpar(h, 'NEXP'))
		endelse
		restore, star_dir + 'field_info.idl'
		obs_summary[i].medflux = info_target.medflux
		obs_summary[i].ra = info_target.ra
		obs_summary[i].dec = info_target.dec
	print_struct, obs_summary[i]
	endfor
	if keyword_set(year) then filename = string((year mod 2000) + 2000, form='(I4)') + '_obs_summary.idl' else filename = 'obs_summary.idl'
	save, obs_summary, filename=filename
 	return, obs_summary
END