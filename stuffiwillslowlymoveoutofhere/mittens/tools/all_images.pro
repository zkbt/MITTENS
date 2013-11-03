PRO all_images, n_max
	common this_star
	restore, star_dir + 'raw_target_lc.idl'
	restore, star_dir + 'jmi_file_prefix.idl'
	image_names = strarr(n_elements(target_lc))
	openr, lun, /get_lun, jmi_file_prefix + '.list'
	readf, lun, image_names
	close, lun
	free_lun, lun
	link_to_images = repstr(jmi_file_prefix + stregex( /ext, image_names, '/.+'), '_list.fits', '.fit')
	for j=0, (n_elements(target_lc) < n_max)-1 do if n_elements(filenames) eq 0 then filenames = master_image_path(link_to_images[j]) else filenames = [filenames, master_image_path(link_to_images[j])]
	print, filenames
	load_image, filenames, /master
END