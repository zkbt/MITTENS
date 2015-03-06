FUNCTION recombine_meridians, east, west
	hjd = [east.hjd, west.hjd]
	i_sort = sort(hjd)
	flux = [east.flux, west.flux]
	fluxerr = [east.fluxerr, west.fluxerr]
	xlc = [east.xlc, west.xlc]
	ylc = [east.ylc, east.ylc]
	airmass = [east.airmass, west.airmass]
	ha = [east.ha, west.ha]
	weight = [east.weight, west.weight]
	flags = [east.flags, west.flags]
	
	return,  {hjd:hjd[i_sort], flux:flux[i_sort], fluxerr:fluxerr[i_sort], xlc:xlc[i_sort], y_lc:ylc[i_sort], $
				airmass:airmass[i_sort], ha:ha[i_sort], weight:weight[i_sort], flags:flags[i_sort], $
				pointer:east.pointer, medflux:east.medflux, x:east.x, y:east.y, j_m:east.j_m, h_m:east.h_m, k_m:east.k_m}
END