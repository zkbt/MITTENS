FUNCTION get_lspm_info, n, noisy=noisy, prefix=prefix
	restore, 'lspm_properties.idl'
	;ld = quad_ld(tte[n], logg[n], 'I')
	lspm = {n:n, ra:ra[n], dec:dec[n], raj2000:raj2000[n], dej2000:dej2000[n], names:names[n], $
			parallax:plx[n], err_parallax:e_plx[n], pmra:pmra[n], pmdec:pmdec[n], $
			v:vmag[n], i:i0[n], z:z0[n], j:jmag[n], h:hmag[n], k:kmag[n],  $
			mass:mass[n], radius:radius[n], logg:logg[n], lum:lum[n], sp:sp[n], teff:(lum[n]/radius[n]^2)^0.25*5780.0};, teff:tte[n], u1:ld.a, u2:ld.b}
	tags = tag_names(lspm)
	if not keyword_set(prefix) then prefix=''
	if keyword_set(noisy) then begin
		print, prefix, "NUTZMAN'S LSPM SUMMARY-O-MATIC"
		for i=0, n_tags(lspm)-1 do print, prefix, '     ', tags[i], ': ', lspm.(i)
				rah = long(lspm.ra/15)
				ram = long((lspm.ra/15 - rah)*60)
				ras = ((lspm.ra/15 - rah)*60 - ram)*60

				decd = long(lspm.dec)
				decm = long((lspm.dec - decd)*60)
				decs = ((lspm.dec - decd)*60-decm)*60

				
				print, 'lspm'+strcompress(/remove_all, n)+"       " + string(rah, format='(I2)') + ":"+ string(ram, format='(I2)')+ ":"+ string(ras, format='(F4.1)') + '      +'+string(decd, format='(I2)')+ ":"+ string(decm, format='(I2)')+ ":"+ string(decs, format='(F4.1)')+ "  2000"

	endif
	return, lspm
END