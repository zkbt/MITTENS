FUNCTION get_mo_info, input_mo, noisy=noisy, prefix=prefix
	common mearth_tools
	mo = name2mo(input_mo)

	; mo_ensemble is a common variable in mearth_tools; this trys to load it only once during a mitten's session
	if n_elements(mo_ensemble) eq 0 then restore, 'population/mo_ensemble.idl'


; 	restore, 'lspm_properties.idl'
; 	;ld = quad_ld(tte[n], logg[n], 'I')
; 	lspm = {n:n, ra:ra[n], dec:dec[n], raj2000:raj2000[n], dej2000:dej2000[n], names:names[n], $
; 			parallax:plx[n], err_parallax:e_plx[n], pmra:pmra[n], pmdec:pmdec[n], $
; 			v:vmag[n], i:i0[n], z:z0[n], j:jmag[n], h:hmag[n], k:kmag[n],  $
; 			mass:mass[n], radius:radius[n], logg:logg[n], lum:lum[n], sp:sp[n], teff:(lum[n]/radius[n]^2)^0.25*5780.0};, teff:tte[n], u1:ld.a, u2:ld.b}
	i = where(mo_ensemble.mo eq mo, n);value_locate(mo_ensemble.lspmn, n)
	if n eq 0 then begin
		mprint, tab_string, error_string, 'problem in get_lspm_info for', mo
		stop
		return, -1
	endif
	mo_info = mo_ensemble[i[0]]
	tags = tag_names(mo_info)
	if ~keyword_set(prefix) then prefix=''
	if keyword_set(noisy) then begin
		print, prefix, "NUTZMAN'S mo_info SUMMARY-O-MATIC"
		for i=0, n_tags(mo_info)-1 do print, prefix, '     ', string(form='(A15)', tags[i]), ': ', string(form='(A15)',mo_info.(i))
				rah = long(mo_info.ra/15)
				ram = long((mo_info.ra/15 - rah)*60)
				ras = ((mo_info.ra/15 - rah)*60 - ram)*60

				decd = long(mo_info.dec)
				decm = long((mo_info.dec - decd)*60)
				decs = ((mo_info.dec - decd)*60-decm)*60

				
				print, 'mo_info'+strcompress(/remove_all, n)+"       " + string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F4.1)') + '      +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F4.1)')+ "  2000"

	endif
	return, mo_info
END