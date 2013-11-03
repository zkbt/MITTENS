FUNCTION guess_inclination, a, soften=soften
	restore, 'exploring_population_spots.idl'
	!x.style=3
	if ~keyword_set(soften) then soften = 1.0
	p_spot_params = exp((-loglike + min(loglike))/soften)
	inc = findgen(91)
	p_of_a_given_i = fltarr(91)
	edge_grid = typical_edge_on_spot_amplitudes#ones(n_elements(nospot_fractions)) 
	de = typical_edge_on_spot_amplitudes[1] - typical_edge_on_spot_amplitudes[0]
	nospot_grid = ones(n_elements(typical_edge_on_spot_amplitudes))#nospot_fractions
	dn = nospot_fractions[1] - nospot_fractions[0]
	p = edge_grid*0.0
	for i_inc=0, n_elements(inc)-1 do begin
		p= spot_amplitude_pdf(a, inc[i_inc]*!pi/180, edge_grid, nospot_grid) 
		!p.multi=[0,2,3,0,1]
		contour, p, typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=20
		contour, p_spot_params, typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=20
		contour, p*p_spot_params, typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=20
		p_of_a_given_i[i_inc] = total( p*p_spot_params*de*dn)
		plot, inc, p_of_a_given_i

	endfor	


	raw_prob = sin(inc*!pi/180)/total(sin(inc*!pi/180))
	boosted_prob = p_of_a_given_i*sin(inc*!pi/180)
	boosted_prob /= total(boosted_prob)
	plot, inc, boosted_prob, yr=[0,max([boosted_prob, raw_prob])]
	oplot, inc, raw_prob, linestyle=1

	a_over_rs = 60.0
	b_is_one = 180/!pi*acos(1.0/a_over_rs)
	vline, linestyle=2, color=150, b_one
	ratio = boosted_prob/raw_prob
	i_transit = where(inc gt b_is_one, n_transit)
	return, mean(ratio[i_transit])
END