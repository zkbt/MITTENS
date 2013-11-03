PRO plot_sample

	s = compile_sample()
	i = where(s.d lt 33 and s.radius lt .35)
	s = s[i]	

	t = tag_names(s)
	for i=0, N_tags(s)-1 do print, i, ' ', t[i]

	i = where(abs(s.pm_ra) lt 2 and abs(s.pm_dec) lt 2)
	loadct, 40
	plot_nd, s[i], tags=indgen(4)+1, psym=3, eps='lspm_positions.eps'
	epstopdf, 'lspm_positions'



	d_mod = 5*alog10(s.d/10)
	loadct, 40

	dis = {v_minus_j:s.v-s.j, v_abs:s.v-d_mod, d_used:s.d, d_plx:1.0/s.plx }
	i_no_plx = where(abs((dis.d_used - dis.d_plx)/dis.d_used) gt 0.01 and dis.d_plx le 0)

	dis = struct_conv(dis)
help
	plot_nd, dis, eps='lspm_distance.eps', psym=3,res=15
	epstopdf, 'lspm_distance'

	loadct, 40
	plot_nd, s, tags=[13,14,15,16, 17, 18], psym=3, eps='lspm_phot.eps', dye=s.d
	epstopdf, 'lspm_phot'

	s.v -= d_mod
	s.i -= d_mod
	s.z -= d_mod
	s.j -= d_mod
	s.h -= d_mod
	s.k -= d_mod

	plot_nd, s, tags=[13,14,15,16, 17, 18], psym=3, eps='lspm_absphot.eps', dye=s.d
	epstopdf, 'lspm_absphot'

	plot_nd, s, tags=[18,12,10,11,9], psym=3, eps='lspm_physical.eps'
	epstopdf, 'lspm_physical'


; 	loadct, 3
; 	p = {v:s.v, k:s.k, v_j:s.v-s.j, v_k:s.v-s.k, j_k:s.j-s.k, distance:s.d, mass:s.mass}
; 	plot_nd, p,  psym=3, eps='lspm_phot.eps', dye=s.t_eff
; 	epstopdf, 'lspm_phot'
END