PRO load_stellar_properties
	query = "select lspmn as n, lspmname, lhs, nltt, hip, tycho, othname, twomass, catra as ra, catdec as dec, pmra, pmdec, vmag as v, rsdss as r, jmag as j, hmag as h, kmag as k, plx, e_plx, plx, e_plx, distmod, numspectype, orig_mass, orig_radius, mass, radius from nc_adopt_best;"
	sql = pgsql_query(query, /verb) 

	lspm = {n:sql.n, ra:sql.ra*180./!pi, dec:sql.dec*180/!pi, names:names[n], $
			parallax:plx[n], err_parallax:e_plx[n], pmra:pmra[n], pmdec:pmdec[n], $
			v:vmag[n], i:i0[n], z:z0[n], j:jmag[n], h:hmag[n], k:kmag[n],  $
			mass:mass[n], radius:radius[n], logg:logg[n], lum:lum[n], sp:sp[n], teff:(lum[n]/radius[n]^2)^0.25*5780.0};, teff:tte[n], u1:ld.a, u2:ld.b}


END