FUNCTION get_lspm_info, n, noisy=noisy, prefix=prefix
	common mearth_tools
	
	; ensemble_lspm is a common variable in mearth_tools; this trys to load it only once during a mitten's session
	if n_elements(ensemble_lspm) eq 0 then restore, 'population/ensemble_lspm_properties.idl'


; 	restore, 'lspm_properties.idl'
; 	;ld = quad_ld(tte[n], logg[n], 'I')
; 	lspm = {n:n, ra:ra[n], dec:dec[n], raj2000:raj2000[n], dej2000:dej2000[n], names:names[n], $
; 			parallax:plx[n], err_parallax:e_plx[n], pmra:pmra[n], pmdec:pmdec[n], $
; 			v:vmag[n], i:i0[n], z:z0[n], j:jmag[n], h:hmag[n], k:kmag[n],  $
; 			mass:mass[n], radius:radius[n], logg:logg[n], lum:lum[n], sp:sp[n], teff:(lum[n]/radius[n]^2)^0.25*5780.0};, teff:tte[n], u1:ld.a, u2:ld.b}
	i = value_locate(ensemble_lspm.lspmn, n)
	if total(abs(ensemble_lspm[i].lspmn - n)) gt 0 then begin
		mprint, tab_string, error_string, 'problem in get_lspm_info for', rw(n)
		return, -1
	endif
	lspm = ensemble_lspm[i]
	tags = tag_names(lspm)
	if ~keyword_set(prefix) then prefix=''
	if keyword_set(noisy) then begin
		print, prefix, "NUTZMAN'S LSPM SUMMARY-O-MATIC"
		for i=0, n_tags(lspm)-1 do print, prefix, '     ', string(form='(A15)', tags[i]), ': ', string(form='(A15)',lspm.(i))
				rah = long(lspm.ra/15)
				ram = long((lspm.ra/15 - rah)*60)
				ras = ((lspm.ra/15 - rah)*60 - ram)*60

				decd = long(lspm.dec)
				decm = long((lspm.dec - decd)*60)
				decs = ((lspm.dec - decd)*60-decm)*60

				
				print, 'lspm'+strcompress(/remove_all, n)+"       " + string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F4.1)') + '      +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F4.1)')+ "  2000"

	endif
	return, lspm
END