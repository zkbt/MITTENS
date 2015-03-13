FUNCTION a_over_rs, mass, radius, period
	return, 4.2096611/radius*mass^(1.0/3.0)*period^(2.0/3.0)
END
