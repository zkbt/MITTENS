PRO ds9_filenames, input_filenames, save_image=save_image,  pixels=pixels, xpa_name=xpa_name, finder=finder, mjd_i_think=mjd_i_think, blank=blank, apertures=apertures, pid=pid

	; insulate the input_filename array from filenames
	if n_elements(input_filenames) gt 0 then filenames = input_filenames

	common this_star

	; set size of image to display
	if not keyword_set(pixels) then pixels=700 ;(makes 10 arcminute box)

	; define path to template to load
	template_path = '/home/zberta/mearth/work/panda.tpl'

	; define place to save images, if saving
	image_path = star_dir + 'field.jpg'

	if keyword_set(finder) then save_image ='lspm'+rw(lspm_info.lspmn)+'_finder_chart.jpg'

	; set up the basics of ds9
	command = 'ds9 -wcs align yes -scale mode zscale -scale squared -cmap invert yes -colorbar no -height '+strcompress(/remove_all, pixels)+' -width '+strcompress(/remove_all, pixels)+' -zoom to 1 ' 

	mprint
	mprint
	mprint, command
	mprint

	; loop over the filenames
	for i=0, n_elements(filenames)-1 do begin
		filename = filenames[i]
		aperture_size = apertures[i]

		; read epoch from header to propagate proper motion
		h = headfits(filename)
		mjd = sxpar(h, 'MJD-OBS') + sxpar(h, 'EXPTIME')/2.0/24./60./60.
		if keyword_set(mjd_i_think) then begin
			if  max((mjd-mjd_i_think[i])*24.*60.*60.) gt 5 then begin
				print, 'MJD of loaded image = ', mjd, ', MJD expected = ', mjd_i_think[i-1], ', offset between them = ', (mjd-mjd_i_think[i-1])*24.*60.*60., ' seconds'
				stop
			endif	
		endif
		date = date_conv(mjd +2400000.5d, 'VECTOR')
		epoch = date[0] + date[1]/365.

		; set target position
		current_ra = double(lspm_info.ra) + (epoch-2000.0)*lspm_info.pmra/60./60./cos(lspm_info.dec*!pi/180)
		rah = long(current_ra/15)
		ram = long((current_ra/15 - rah)*60)
		ras = ((current_ra/15 - rah)*60 - ram)*60
		current_dec = double(lspm_info.dec) + (epoch-2000.0)*lspm_info.pmdec/60./60.
		decd = long(current_dec)
		decm = long((current_dec - decd)*60)
		decs = ((current_dec - decd)*60-decm)*60
		pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)');+ "  (J2000)"

		; define a position a little south of the target, for labeling purposes
		south_dec = double(lspm_info.dec) + (epoch-2000.0)*lspm_info.pmdec/60./60. - 4.0/60.0
		decd = long(south_dec)
		decm = long((south_dec - decd)*60)
		decs = ((south_dec - decd)*60-decm)*60
		south_pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)');+ "  (J2000)"
		label_string = string(format='(F10.4)', mjd) 
		south_label_string ='lspm' + rw(lspm_info.lspmn) + ' on ' + date_conv(mjd+2400000.5d - 7.0/24.0, 'S')
		print, label_string

		if keyword_set(finder) then label_string = "MEarth master image; 6 arcminutes"

		this_line_of_command =  filename  + ' -pan to '+strcompress(pos_string) + ' fk5  '							
		if ~keyword_set(blank) then this_line_of_command += "-regions command 'fk5; box("+pos_string+', 360", 360") # dash=1 width=4 color=black font="helvetica 18 bold" text = "'+label_string+'" '+ "' -regions command 'fk5; circle("+south_pos_string+',0")'+'# width=0 color=black font="helvetica 18 bold" text = "'+south_label_string+'" '+ "' -regions command 'fk5; circle("+pos_string+','+string(format='(F4.1)', aperture_size)+"i) # width=4 color=red' "
		print, this_line_of_command
		print
		command += this_line_of_command
	endfor	
	rest_of_command =  '-single -frame next -match frame wcs -raise'
	print, rest_of_command
print
print
	command += rest_of_command
	if n_elements(save_image) gt 0 then command += ' -saveimage jpeg ' + save_image + ' -exit'
	command+='&'
	print

	
	spawn, command, result, pid=pid
	
	wait, n_elements(filenames)*0.4 > 5
	xpa_command = "xpaget xpans | tail -1 | awk '{print $4}'"
	spawn, xpa_command, xpa_name
	print, 'XPA access running through ', xpa_name
	if keyword_set(finder) then spawn, 'konqueror ' + save_image + '&'


END