FUNCTION is_uptodate, file_of_interest, file_to_compare
  a = file_info(file_of_interest)
  b = file_info(file_to_compare)
  return, a.mtime gt b.mtime
END