sigma_r = 0.9
mean_r = 2
max_r = 5.0
r = (findgen(1000)+1)/100
greater_than_one = r ge 1.0
gauss = 1/sqrt(2*!pi)/sigma_r*exp(-0.5*(r - mean_r)^2/sigma_r^2)
jeffrey = alog(max_r)/r
g = 0.5
j = 0.5
plot, r, greater_than_one*(gauss* jeffrey)
oplot, linestyle = 1, r, gauss*g
oplot, linestyle = 1, r, jeffrey*j


n_obs = 300.
lnp = -n_obs*alog(r) - 1./2./r^2*(4*n_obs)
lnp -= max(lnp)
plot, r, lnp, xr=[.9,10], xs=1
oplot, r, -alog(r), linestyle=1
oplot, r,-0.5*(r - mean_r)^2/sigma_r^2, linestyle=1
