FUNCTION g, x
  return, (0.5 + 0.5*erf(double(x)/sqrt(2)))  
END

FUNCTION ccdf, x, bin=bin
  if keyword_set(bin) then begin
    h = histogram(x, locations=locations, bin=bin)
    ccdf = 1.0 - total(h, /cumulative)/total(h)
    i = where(ccdf gt 0)
    return, {x:locations[i], y:ccdf[i]}
  endif
    
  n = n_elements(x)
  i = sort(x)
  ccdf = 1.0d - total(ones(n), /cum, /double)/n
  j = where(ccdf gt 0)
  return, {x:x[i[j]], y:ccdf[j]}

END