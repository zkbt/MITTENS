FUNCTION phase_lc, lc, candidate
    pad = long((max(lc.hjd) - min(lc.hjd))/candidate.period) + 1
	phased_time = (lc.hjd-candidate.hjd0)/candidate.period + pad + 0.5
	orbit_number = long(phased_time)
    phased_time = (phased_time - orbit_number - 0.5)*candidate.period
	phased_lc = lc
	phased_lc.hjd = phased_time/candidate.period
;	phased_lc = phased_lc[sort(phased_time)]
	return, phased_lc
END