FUNCTION mad, x, nan=nan
	if n_elements(x) eq 1 then return, x
	return, median(abs(x - median(x)))
END
