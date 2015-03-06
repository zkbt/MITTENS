PRO file_remove_empty_directories
	spawn, 'pwd'
	if question(/int, 'Are you sure you want to remove all empty directories in the above path?') then spawn, 'find . -type d -empty -exec rmdir {} \;'
END