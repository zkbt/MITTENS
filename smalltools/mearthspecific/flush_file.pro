PRO flush_file, filename
	
	f = file_search(['ls*/ye*/*/'+filename, 'ls*/*/'+filename])
	mprint, /line
	mprint, f 
	if f[0] eq '' then begin
		mprint, 'No inprogress.txt files exist that need to be flushed!'
		return
	endif
	mprint, ' Do you want to delete all of the above files?'
	if question('', /int) then begin
		file_delete, f
		mprint, "Okay, they're deleted!"
	endif
END