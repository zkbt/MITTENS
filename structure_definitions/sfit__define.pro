PRO sfit__define
   	struct = {sfit, $
				sfit_period:0.0, $ ;    Period (days) of dominant periodogram peak.
				sfit_phase:0.0, $ ;     Phase (rad) relative to MJDBASE.
				sfit_amp:0.0, $ ;       Amplitude in A*sin(omega*t + phase) in mag.
				sfit_dc:0.0, $ ;        DC offset.
				sfit_cm:0.0, $ ;        sfit_cm * common_mode(t) correction coefficient
				sfit_merid:0.0, $ ;     Meridian flip correction (add if IANG=0, subtract if IANG=1).
				sfit_fwhm:0.0, $ ;      sfit_fwhm * (fwhm(t) - median(fwhm)) correction coefficient.
				sfit_chidof:0.0, $ ;    Chi squared per dof after subtracting sin at fundamental.
				sfit_chismooth:0.0, $ ; Chi squared per dof after subtracting smoothed phase-folded version of curve.
				sfit_chibefore:0.0, $ ; Chi squared per dof before fitting.
				sfit_npt:0.0, $ ;       Number of points in fit.
				sfit_fstat:0.0, $ ;     F statistic for sin at fundamental model.
				sfit_fsmooth:0.0, $ ;   F statistic for smoothed, phase folded model.
				sfit_nparmnull:0.0, $ ; Number of parameters in null hypothesis (flat + systematics corrections) model.
				sfit_nparmfit:0.0} ;   Number of parameters in sin model.
END