FUNCTION user_candidate
	candidate = {candidate}
	period = 0.d
	hjd0 = 0.d
	read, prompt='period = ', period
	candidate.period = period
	read, prompt='hjd0 = ', hjd0
	candidate.hjd0 = hjd0
	read, prompt='duration = ', duration
	candidate.duration = duration
	read, prompt='depth = ', depth
	candidate.depth = depth

	print_struct, candidate
	return, candidate
END