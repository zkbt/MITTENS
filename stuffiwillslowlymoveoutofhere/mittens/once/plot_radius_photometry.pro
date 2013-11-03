PRO plot_radius_photometry
  restore, 'p.idl'
  set_plot, 'ps'
  device, filename='radius_vs_photometry.eps', /enca, /color, /inch, xsize=7, ysize=5
  @psym_circle
      !p.charsize=1.3
    !x.thick=4
    !y.thick=4
    !p.charthick=4
     !p.symsize=0.2
     i = uniq(p.lspm, sort(p.lspm))
     p = p[i]
     
  plot, psym=8, symsize=0.5, p.stellar_radius, sqrt(p.planet_1sigma), xtitle=goodtex('Stellar Radius (R_{solar})'),$
   ytitle=goodtex('Per Point Photometric Precision (R_{Earth})'), yrange=[0,5], xrange=[0.08, 0.37], /xs
  device, /close
  epstopdf, 'radius_vs_photometry.eps'
END