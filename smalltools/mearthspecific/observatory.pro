FUNCTION observatory
	te = long(stregex(/ex, te_dir(), '[0-9]+'))
	if te ge 1 and te le 8 then obs = 'N'
	if te ge 11 and te le 18 then obs ='S'
	return, obs
END