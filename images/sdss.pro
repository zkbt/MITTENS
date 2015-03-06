PRO sdss, lspm
  mo_info = get_mo_info(lspm)
  str = '"http://cas.sdss.org/dr7/en/tools/chart/chart.asp?ra='+strcompress(/remo, mo_info.ra)+'&dec='+strcompress(/remo, mo_info.dec)+'&scale=1.52440&opt=&width=1024&height=1024"'
  spawn, 'firefox ' + str
END