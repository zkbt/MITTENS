FUNCTION inverse_erf, p
	; works up to p~erf(5)
	p = double(p)
	z_final = dblarr(n_elements(p))
	for i = 0l, n_elements(p)-1 do begin
		z=0.0d
		while (abs(erf(z[n_elements(z)-1]) - p[i]) gt 1d-10) do begin
			z_new = z[n_elements(z)-1] - (erf(z[n_elements(z)-1])-p[i])/2.0*sqrt(!pi)/exp(-z[n_elements(z)-1]^2)
			z = [z,z_new]
		endwhile
		z_final[i] = z[n_elements(z)-1]
	endfor
	return, z_final
END