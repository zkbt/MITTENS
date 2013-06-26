PRO ds9, images, file_prefixes, zscale=zscale, pause=pause, zoom=zoom, rotate=rotate
;+
; NAME:
;    ds9
; 
; PURPOSE:
; 
;      Display an image, or an array of images, in ds9!
; 
; CALLING SEQUENCE:
; 
; INPUTS:
; 	images 		= [x_size, y_size, n_images] array of images to display
;				(N.B. you can create such an array with [[[img1]],[[img2]],[[..]]])
;	file_prefixes 	= (optional) filenames (- ".fits") for the temporary files
;
; KEYWORD PARAMETERS:
;	/zscale 	=	display colors in zscale
;	zoom	=	zoom to the value specified (a number or the string "fit" are allowed)
;	rotate	=	number of degrees to rotate image
;
; OUTPUTS:
; 
; RESTRICTIONS:
; 
; EXAMPLE:
; 
; MODIFICATION HISTORY:
; 	Created 9-Nov-10 by ZKB.
;-
	command = 'ds9 '
	
	if keyword_set(zscale) then command += '-zscale '
	if keyword_set(zoom) then command += '-zoom to ' + strcompress(/rem, zoom) + ' ' 
	if keyword_set(rotate) then command += '-rotate ' + strcompress(/rem, rotate) + ' ' 
	
	for i=0, n_elements(images[0,0,*])-1 do begin
		if keyword_set(file_prefixes) then begin
			filename = file_prefixes[i] + '.fits' 
		endif else begin
			filename = 'temp'+strcompress(/remove_all, i)+'.fits'
		endelse
		if file_test(filename) then file_delete, filename
		mwrfits, images[*,*,i], filename
		command += filename + ' '
	endfor
	command += '-tile no -frame first'
	if not keyword_set(pause) then command += '&'
	spawn, command
END