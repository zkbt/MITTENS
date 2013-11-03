PRO print_transit, transit
      common mearth_tools
      mprint, tab_string, tab_string, '             hjd0 = ', mjd2hopkinsdate(transit.hjd0)
      mprint, tab_string, tab_string, '         duration = ', strcompress(/remov, string(format='(F5.3)', transit.duration)), ' = ', strcompress(/remo, string(format='(F3.1)', transit.duration*24)), ' hr'
      mprint, tab_string, tab_string, 'points in transit = ', strcompress(/remo, transit.i_stop - transit.i_start + 1)
      mprint, tab_string, tab_string, '            depth = ', string(format='(F5.3)', transit.depth)
      mprint, tab_string, tab_string, '       deltachi^2 = ', strcompress(/remo, string(format='(F10.1)', transit.deltachi))
END