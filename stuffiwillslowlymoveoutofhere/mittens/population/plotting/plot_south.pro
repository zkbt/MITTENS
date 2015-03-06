PRO plot_south
	readcol, '~/newsouth.txt', ra, dec, pm , v,j,h,k,dmod, radius
	s = {ra:ra, dec:dec,distance:10*10^(dmod/5), radius:radius, v:v, v_minus_j:v-j, k:k};, k_abs:k -dmod}; pm:pm,
	loadct, 40
help
	plot_nd,s, label='LSPM-south from Philip', psym=3, eps='lspm_south.eps', charsize=0.5
	epstopdf, 'lspm_south'
END