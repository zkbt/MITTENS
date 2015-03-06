FUNCTION question, prompt, interactive=interactive, number=number, string=string
	if keyword_set(interactive) then begin
		print, prompt + ' (y = yes, q = quit, s = stop asking)'
		response = strarr(1)
		read, response
		if keyword_set(string) then return, response
		if keyword_set(number) then return, double(response)
		if strmatch(response, '*q*', /fold_case) gt 0 then stop
		if strmatch(response, '*s*', /fold_case) gt 0 then interactive =0
		return, strmatch(response, '*y*', /fold_case)
	endif else return, 0
END