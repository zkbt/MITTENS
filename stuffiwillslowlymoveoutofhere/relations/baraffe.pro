FUNCTION baraffe, mass
	; only solar metallicity
	; only lmix = 1.0
	; only 5 Gyr
	m = mrdfits('/home/zberta/idl_routines/zkb/relations/baraffe.fit', 1, h)
	m = m[where(m.lmix eq 1.0 and m._m_h_ eq 0.0 and m.age gt 4.9 and m.age lt 5.1)]
	logg = interpol(m.logg, m.mass, mass)
	@constants
	radius = sqrt(g*mass*m_sun/(10.0^logg))/r_sun
	return, radius
END