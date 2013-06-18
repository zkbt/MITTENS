PRO sdss, lspm
  lspm_info = get_lspm_info(lspm)
  str = '"http://cas.sdss.org/dr7/en/tools/chart/chart.asp?ra='+strcompress(/remo, lspm_info.ra)+'&dec='+strcompress(/remo, lspm_info.dec)+'&scale=1.52440&opt=&width=1024&height=1024"'
  spawn, 'firefox ' + str
END