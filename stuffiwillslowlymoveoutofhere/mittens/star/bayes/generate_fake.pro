FUNCTION generate_fake
	common mearth_tools
	f = {fake}
	min_period = 0.25
	max_period = 20.0
	f.period = randomu(seed)*(max_period - min_period) + min_period
	f.hjd0 = randomu(seed)*f.period + 55000.0d
	f.radius = radii[randomu(seed)*n_elements(radii)]
	f.b = randomu(seed)
	return, f
END