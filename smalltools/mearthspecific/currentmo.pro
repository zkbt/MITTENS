FUNCTION currentmo
  if star_dir() eq '' then return, '???'
  return, name2mo(star_dir())
END