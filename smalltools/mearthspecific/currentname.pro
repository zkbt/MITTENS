FUNCTION currentname
  if star_dir() eq '' then return, '???'
  return, mo2name(currentmo())
END