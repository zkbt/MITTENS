PRO epstopng, filename, dpi=dpi, hide=hide
  	if strmatch(filename, '*.eps') ne 0 then name = strmid(filename, 0, strpos(filename, '.eps')) else name = filename

	if not keyword_set(dpi) then dpi = 72
	spawn, "umask 0007; convert -density "+ strcompress(dpi, /remove_all) + " " + name +'.eps ' + name+'.png&'
	
	if ~keyword_set(hide) then begin
		wait, 3
		 spawn, 'konqueror ' + name + '.png &'
	endif
END