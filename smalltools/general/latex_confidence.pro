FUNCTION latex_confidence, x, f_central, f_errors, sym=sym, central=central, auto=auto, nodollars=nodollars
	
	if not keyword_set(f_central) then f_central = ''
	if not keyword_set(f_errors) then f_errors = ''
	
	n = n_elements(x)
	left = 0.157*n
	middle = 0.5*n
	right = (1.0 - 0.157)*n
	y = x[sort(x)]
	if keyword_set(central) then center = central else center = y[middle]
	if stddev(x) eq 0 then return, '$' + strcompress(/remove, string(center, format=f_central)) + '$' 

	pos_err = y[right] - center
	neg_err = center - y[left]
	sym_err = (pos_err + neg_err)/2.0

	if keyword_set(auto) then begin
		ndig =alog10(mean([(pos_err), (neg_err)])) > (-100)
		if ndig lt 0 then begin
			f_errors = '(D20.' + strcompress(round(-ndig+1), /remo) + ')'
		endif else begin
			f_errors = '(I20)'; + strcompress(round(-ndig+1), /remo) + ')'
		endelse
		f_central = f_errors
		threshold = 0.1
		if abs((pos_err - sym_err)/sym_err) lt threshold and abs((neg_err-sym_err)/sym_err) lt threshold then sym =1
	endif

	top_str = strcompress(/remove, string(pos_err, format=f_errors))
	bot_str = strcompress(/remove, string(neg_err, format=f_errors))
	sym_str = strcompress(/remove, string(sym_err, format=f_errors))



	if keyword_set(sym) then begin
		if keyword_set(nodollars) then return, strcompress(/remove, string(center, format=f_central)) + '\pm'+ sym_str
		return, '$' + strcompress(/remove, string(center, format=f_central)) + '\pm'+ sym_str + '$' 
	endif else begin
		if keyword_set(nodollars) then return, strcompress(/remove, string(center, format=f_central)) + '^{+'+top_str+'}_{-'+bot_str+'}'
		return, '$' + strcompress(/remove, string(center, format=f_central)) + '^{+'+top_str+'}_{-'+bot_str+'}' + '$'
	endelse
END