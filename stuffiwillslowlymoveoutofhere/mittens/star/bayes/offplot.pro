PRO offplot, x, y, color=color
	i_leftright = where(x gt max(!x.crange) or x lt min(!x.crange), n_leftright)
	for i=0, n_leftright-1 do begin
		this_x = x[i_leftright[i]]
		this_y = y[i_leftright[i]]
		edge = where(abs(!x.crange -this_x) eq min(abs(!x.crange -this_x) ), complement=other_edge, n_edge)
		arrow, !x.crange[edge[0]] + (!x.crange[other_edge[0]] - !x.crange[edge[0]])/20, this_y, !x.crange[edge[0]], this_y, /data, color=color
	endfor

	i_updown = where(y gt max(!y.crange) or y lt min(!y.crange), n_updown)
	for i=0, n_updown-1 do begin
		this_x = x[i_updown[i]]
		this_y = y[i_updown[i]]
		edge = where(abs(!y.crange -this_y) eq min(abs(!y.crange -this_y) ), complement=other_edge, n_edge)
		arrow, this_x, !y.crange[edge[0]] + (!y.crange[other_edge[0]] - !y.crange[edge[0]])/10,  this_x, !y.crange[edge[0]],  /data, hsize=-.5, color=color
	endfor
END