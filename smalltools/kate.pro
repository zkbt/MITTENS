PRO kate, procedure_name
	doc_library, procedure_name, print = 'grep " Documentation for /" > temporary.filename'
	spawn, "awk '{print $4}' temporary.filename", result, error
	print, result
	if error ne '' then print, error

	spawn, "kate `awk '{print $4}' temporary.filename` &", result, error
	if error ne '' then print, error
END