FUNCTION mixed_chisqr_cdf, x, degree, weights, rescaling
  n = n_elements(weights)
  cdf = dblarr(n_elements(x))
  for i=0, n-1 do begin
    cdf += weights[i]*chisqr_pdf(x/rescaling[i], degree)
  endfor
  return, cdf
END