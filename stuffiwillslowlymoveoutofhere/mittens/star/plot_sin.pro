PRO plot_sin, eps=eps, period_range=period_range
  common this_star
  if file_test(star_dir + 'decorrelated_lc.idl') eq 0 then return
  restore, star_dir + 'decorrelated_lc.idl'
	if not keyword_set(period_range) then period_range=[.01, 300]
  periodogram, decorrelated_lc, sin_params=sin_params, period_range=period_range
  print_struct, sin_params
 ;   if sin_params.a gt 0.005 then begin
    xplot, 1
    plot_lightcurves, sin=sin_params, /time, eps=eps
    xplot, 2
    plot_lightcurves, sin=sin_params, /time, eps=eps, /phased
  ; endif
END