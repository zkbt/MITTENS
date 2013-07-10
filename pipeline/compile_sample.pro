FUNCTION compile_sample
	restore, 'population/ensemble_lspm_properties.idl'
; 	lspms = {lspm:tlspm, ra:double(tra), dec:double(tdec), pm_ra:tpmra, pm_dec:tpmdec, plx:plx[tlspm], d:10^(tdmod/5+1), logg:tlogg, lum:tlum, t_eff:tte, radius:tradius, sp:tsp, mass:tmass, v:tvmag, i:ti0, z:ti0, j:tjmag,  h:thmag, k:tkmag}
; 	lspms = struct_conv(lspms)
; 	return, lspms
	return, ensemble_lspm
END