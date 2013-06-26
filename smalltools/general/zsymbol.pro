FUNCTION zsymbol, earth=earth, sun=sun
	if keyword_set(earth) then return, '!20S!3'
	if keyword_set(sun) then return, '!9n!3'
END