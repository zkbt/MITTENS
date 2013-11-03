FUNCTION perturb_stellar_mass, m_orig
	sig_obs = 0.3*m_orig
	M_bochan = 0.25
	sig_bochan = 0.28
	m_grid = findgen(90)*0.01 + 0.1
	prob = exp( -(m_grid - m_orig)^2/2/sig_obs^2 - (alog10(m_grid) - alog10(m_bochan))^2/2/sig_bochan^2)
	cumulative = total(prob, /cum)/total(prob)
	new = interpol(m_grid, cumulative, randomu(seed))
	

; 	plot, m_grid, exp(-(m_grid - m_orig)^2/2/sig_obs^2), linestyle=2
; 	oplot, m_grid,exp( - (alog10(m_grid) - alog10(m_bochan))^2/2/sig_bochan^2), linestyle=1
; 	oplot, m_grid,exp( -(m_grid - m_orig)^2/2/sig_obs^2 - (alog10(m_grid) - alog10(m_bochan))^2/2/sig_bochan^2)
; 	vline, new
	return, new
END