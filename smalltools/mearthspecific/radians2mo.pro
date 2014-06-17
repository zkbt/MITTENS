FUNCTION radians2mo, ra, dec

	common mearth_tools

	if n_elements(ra) ne n_elements(dec) then begin
		mprint, tab_string, error_string, "radians2mo.pro is upset that it wasn't fed RA and DEC arrays of the same length"
		stop
	endif
	str = strarr(n_elements(ra))
	for i=0, n_elements(ra)-1 do begin

		ra_hours= ra[i]*180d/!dpi/15.0
		dec_deg= dec[i]*180d/!dpi
		
		ras = sixty(ra_hours)
		decs = sixty(dec_deg)
	
		; get RA in format of hhmmss(.)ss
		ra_string = 	string(form='(I02)', ras[0]) + $
				string(form='(I02)', ras[1]) + $
				string(form='(I02)', floor(ras[2])) + $
				string(form='(I02)', floor((ras[2] - floor(ras[2]))*100))
		
		; get the + or - right
		if dec_deg ge 0 then symbol = '+' else symbol = '-'
	
		; get DEC in format of ddmmss(.)s
		dec_string = 	string(form='(I02)', decs[0]) + $
				string(form='(I02)', decs[1]) + $
				string(form='(I02)', floor(decs[2])) + $
				string(form='(I01)', floor((decs[2] - floor(decs[2]))*10))
		str[i] = ra_string + symbol + dec_string
	endfor

	return,  str
END