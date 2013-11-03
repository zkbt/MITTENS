PRO make_border
  n = 500
  t = findgen(n)/n*1.0
  @constants
  set_plot, 'ps'
  device, filename='border.eps', /inches, xsize = 12, ysize=1, /enc
  transit = -2.5*alog10(zeroeccmodel(t,0.0,0.3,0.16,0.2,2.5*r_earth/r_sun,!pi/2,0.0,0.2,0.6))
  f = transit + randomn(seed, n)*0.002 + sin(t*13)*0.005
  @psym_circle
  plot, t, f, yrange=[max(f), min(f)], xs=5, ys=5, psym=-8, symsize=0.2
  device, /close
  epstopdf, 'border.eps'
END