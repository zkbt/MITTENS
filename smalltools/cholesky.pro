FUNCTION cholesky, c
	q = c
	choldc, q, p, /double
	n = n_elements(c[*,0])
	l = q
	for i=0, n-1 do for j=0, n-1 do if i eq j then l[i,j] = p[i] else if i gt j then l[i,j]=0
	return, l

END