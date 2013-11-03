FUNCTION delfosse, Mk
	logmass = 0.001*(1.8 + 6.12*Mk + 13.205*Mk^2 - 6.2315*Mk^3 + 0.37529*Mk^4)
	i_below = where(Mk gt 10.78, n_below)
	if n_below gt 0 then begin
		 logmass[i_below] = alog10(0.075)
		PRINT, '&)!%&*!#%^*(_ watch out! you might be below the Delfosse relation!'
	endif
	return, 10.0^logmass
END