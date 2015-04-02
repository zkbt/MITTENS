PRO mittens_permissions, path
	if not keyword_set(path) then path = mo_dir()

	mprint, 'tidying up permissions'
	if strmatch(mo_dir(), '*mo*') then begin
	  ;b = question('going to fix ' + path, /interactive)
	  spawn, 'chgrp -R exoplanet ' + path, result, error
	  spawn, 'chmod -R u+rwx,g+rwxs ' + path, result, error
	endif
END