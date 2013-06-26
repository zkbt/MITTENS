FUNCTION covariance, x, y
	if (n_elements(x) ne n_elements(y)) then print, '   !&(%#@! input arrays of different length! (covariance)'
	return, total((x - mean(x))*(y- mean(y)))/(n_elements(x)-1)
END
