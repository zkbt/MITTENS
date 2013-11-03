PRO plot_transit, transit, lc=lc, n_lc=n_lc
  common this_star
  if not keyword_set(n_lc) then n_lc=1
  xplot, 12
  cleanplot, /silent
  xplot, 12
  plot_lightcurves, 1, /time, transit=transit, wtitle=star_dir + ' | best guess | HJDo (fixed to) ' + string(transit.hjd0, format='(F9.3)') + ' = ' + date_conv(transit.hjd0+2400000.5d - 7.0/24.0, 'S'), lc=lc
END