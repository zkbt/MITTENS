FUNCTION master_image_path, file

	; try the following
	; 	print, master_image_path('/data/mearth2/2008-2010-iz/reduced/tel01/master/lspm87_master.fit')
	; it probably won't work
 
	master_file = file_search(file, /fully_qualify_path)
	master_dir = stregex(/extract, master_file, '.+master/')
	reduced_dir = stregex(/extract, master_file, '.+reduced/')
	info = file_info(master_file)
	
	if info.exists eq 0 then print, 'file ', file, ' does not exist! :('

	; return for the easy case
	if info.regular then return, info.name

	; follow a real symlink if it exists
	if info.symlink then return, file_readlink(info.name)

	; follow a fake symlink if it doesn't
	if info.dangling_symlink then begin
		linked_file = master_dir + file_readlink(info.name)
		info = file_info(linked_file)
		if info.dangling_symlink then linked_file = file_readlink(info.name)
		info = file_info(linked_file)
	;	disk_fixed = repstr(info.name, 'mearth1', 'mearth2')
		assumed_reduced_dir = stregex(/extract, info.name, '.+reduced/')
		dir_fixed = repstr(info.name, assumed_reduced_dir, reduced_dir)
		return, dir_fixed
	endif

	print, 'UH-OH! there was, unsurprisingly, a case Zach did not consider'

END