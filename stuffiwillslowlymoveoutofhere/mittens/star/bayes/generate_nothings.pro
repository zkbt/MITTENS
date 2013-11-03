FUNCTION generate_nothings, lc

	; setup environment
	common this_star
	common mearth_tools
	@data_quality
	@filter_parameters

	nights = round(lc.hjd - mearth_timezone())
	uniq_nights = uniq(nights, sort(lc.hjd))
	
	one_nothing = {hjd:0L, n:0, rescaling:0.0}
	nothings = replicate(one_nothing, n_elements(uniq_nights))
	nothings.hjd = round(lc[uniq_nights].hjd - mearth_timezone())
	
	return, nothings
END