; median filter parameters
	; filtering time (full width, centered on each data point)
	mf_long_time = 2.0
	; shorter time for the mean resmoothing of the median smoothed light curve
	mf_short_time = mf_long_time/4.0

; decorrelation parameters
	; which external variables can be used
;	ev_tags = ['AIRMASS', 'SEE',  'HUMIDITY', 'MERID',  'SKY', 'COMMON_MODE'];, 'SKYTEMP''EXPTIME'];'LEFT_XLC', 'RIGHT_XLC', 'LEFT_YLC', 'RIGHT_YLC', 'ELLIPTICITY',]'PRESSURE',
	ev_tags = ['COMMON_MODE', 'HUMIDITY','SKYTEMP'];, 'SEE'];,'AIRMASS'];, 'ELLIPTICITY', 'SKY', 'RIGHT_XLC'];, 'SKYTEMP''EXPTIME'];'LEFT_XLC', 'RIGHT_XLC', 'LEFT_YLC', 'RIGHT_YLC', 'ELLIPTICITY',]'PRESSURE',
	optional_ev_tags = ['SEE','AIRMASS',  'ELLIPTICITY'];'SKY',

	; how much noisier a comparison star can be relative to target to be used
	comparison_star_noise_excess_factor = 2.0
	; threshold for throwing out points in target light curve
	n_sigma_consider = 4.0
	; Spearman rank correlation significance level required to include template in decorrelation
	spearman_sig_threshold = 0.0001
	; maximum ratio of number of templates (M) to number of datapoints (N)
	m_to_n_ratio = 0.005

; iteration parameters
	; required agreement between successive light curves to call converged (in magnitudes)
	convergence_limit = 1.0e-4

timezone = mearth_timezone()