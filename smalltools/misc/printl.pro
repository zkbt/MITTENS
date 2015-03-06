PRO printl, s
	if keyword_set(s) then print, replicate(s, 20) else print, '======================================='
END