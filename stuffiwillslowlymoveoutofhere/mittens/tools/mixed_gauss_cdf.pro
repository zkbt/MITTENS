FUNCTION g, x
  return, (0.5 + 0.5*erf(double(x)/sqrt(2)))  
END

FUNCTION mixed_gauss_cdf, x, degree, weights, rescaling
  n = n_elements(weights)
  cdf = dblarr(n_elements(x))
  for i=0, n-1 do begin
    cdf += weights[i]*g(x/rescaling[i])
  endfor
  return, cdf
END