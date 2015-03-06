FUNCTION confidence_interval, x
	n = n_elements(x)
	left = 0.157*n
	middle = 0.5*n
	right = (1.0 - 0.157)*n
	y = x[sort(x)]
	return, y[[left, middle, right]]
END