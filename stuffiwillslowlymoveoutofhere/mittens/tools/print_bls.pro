PRO print_candidate, candidate
	common this_star
	if not keyword_set(folder) then folder = 'blind/best/'
	restore, star_dir + folder +'candidate.idl'

  	tel_string = stregex(/ex, star_dir, 'tel[0-9]+')
  	lspm_string = stregex(/ex, star_dir, 'lspm[0-9]+')
		;b = big_bls[0, which]
		openw, email_lun, /get_lun, star_dir + folder + 'email.txt'

	restore, star_dir + 'medianed_lc.idl'
			phased_t = ((medianed_lc.hjd - candidate.hjd0 + 0.5*candidate.period) mod candidate.period) - 0.5*candidate.period
			in_transit = where(abs(phased_t) le candidate.duration/2.0, complement=out_transit, n_int)
				transit_number = long((medianed_lc[in_transit].hjd - candidate.hjd0 + candidate.period/2.0)/candidate.period)
				unique_transit_number = transit_number[uniq(transit_number, sort(transit_number))]

		pos_string = ''
		openr, lun, star_dir + '/pos.txt', /get_lun
		readf, lun, pos_string, format='(A100)'
		close, lun
		free_lun, lun
			printf, email_lun, '==============================='
			printf, email_lun, star_dir;file_search(star_dir, /fully) + '/index.htm'
			printf, email_lun,  '==============================='

			printf, email_lun, ''
	@constants
	printf, email_lun, 'THE STAR'
			printf, email_lun, '   ra + dec = '+pos_string

						printf, email_lun, '   px = ', string(format='(F5.3)', lspm_info.parallax), ' +/- ', string(format='(F5.3)', lspm_info.err_parallax)
						printf, email_lun, '   pm = ', strcompress(string(format='(F5.2)', lspm_info.pmra)), ' ', string(format='(F5.2)', lspm_info.pmdec)
						printf, email_lun, '   V = ', string(format='(F4.1)', lspm_info.v)
						printf, email_lun, '   I = ', string(format='(F4.1)', lspm_info.i)
						printf, email_lun, '   J = ', string(format='(F4.1)', lspm_info.j)
						printf, email_lun, '   H = ', string(format='(F4.1)', lspm_info.h)
						printf, email_lun, '   K = ', string(format='(F4.1)', lspm_info.k)
			printf, email_lun, '   mass = ', string(lspm_info.mass, format='(F4.2)')
			printf, email_lun, '   radius = ', string(lspm_info.radius, format='(F4.2)')
			printf, email_lun, '   teff = ', string(lspm_info.teff, format='(I4)')

	printf, email_lun, ''
	printf, email_lun, 'CURRENT BEST CANDIDATE'
				printf, email_lun,  '   period = ', string(candidate.period, format ='(D12.9)')
				printf, email_lun,  '   HJDo = ', string(candidate.hjd0+2400000.5d, format ='(D14.6)'), ' = ', string(candidate.hjd0, format ='(D12.6)'), ' (modified)'
				printf, email_lun,  '   duration = ', string(candidate.duration, format ='(D5.3)'), ' = ',  string(candidate.duration*24, format ='(D4.2)') + ' hours'
				printf, email_lun,  '   depth = ', string(candidate.depth, format ='(D6.4)'), ' = ', string(candidate.depth^0.5*lspm_info.radius*r_solar/r_earth, format ='(D6.4)'), ' Earth'
				printf, email_lun,  '   chi^2 = ', string(candidate.chi, format ='(D5.1)')
		;		printf, email_lun,  '   ratio = ', string(candidate.chi/max(-big_bls[1,*].chi), format ='(D4.1)')
				printf, email_lun,  '   f = ', string(candidate.f, format ='(D4.2)')
				printf, email_lun,  '   fap = ', strcompress(/remo, string(candidate.fap, format='(G10.4)'))
				ecc = 0.0
				sini=1.0
				@constants	
				planet_radius = candidate.depth^0.5*lspm_info.radius*r_solar
				planet_density = 2.0
				planet_mass = planet_density*4*!pi/3.0*planet_radius^3
				k = planet_mass*sini/sqrt(1-ecc^2)*(2*!pi*g/(candidate.period*day)/(lspm_info.mass*m_sun)^2)^(1.0/3.0)
				printf, email_lun,  '   RV semiamplitude = ', strcompress(/remo, string(format='(F5.1)', k/100)), ' m/s (for a density of 2 g/cc)'
				printf, email_lun,  '   a/R* = ', string(format='(I4)', a_over_rs(lspm_info.mass, lspm_info.radius, candidate.period)) 
				teq = lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, candidate.period))^0.5
				printf, email_lun,  '   equilibrium temperature = ', strcompress(/remo, string(format='(I10)', teq)) , 'K (for zero albedo)' 
printf, email_lun, ''


			;	printf, email_lun,  '   false alarm: ', string(pfa[k], format='(D)')

	openw,  lun,'temp.skycalc', /get_lun
	printf, lun, 'h'
	spaces = strsplit(pos_string)
	printf, lun,'r ', strmid(pos_string, spaces[0], spaces[1]-1)
	printf, lun, 'd ', strmid(pos_string, spaces[1], 1000)
	printf, lun, 'h'
	printf, lun, star_dir
	printf, lun, 'xv'
	printf, lun, candidate.period
	printf, lun, candidate.duration/max(unique_transit_number)
	printf, lun, candidate.hjd0+2400000.5d
	printf, lun, candidate.duration/2.0
	caldat, systime(/julian), month, day, year
	printf, lun, string(format='(I4)', year) + ' ' + string(format='(I2)', month) + ' ' + string(format='(I2)', day)
	caldat, systime(/julian)+100, month, day, year
	printf, lun,  string(format='(I4)', year) + ' ' + string(format='(I2)', month) + ' ' + string(format='(I2)', day)
	printf,  lun, '-1'
	printf,  lun, '90'
	printf, lun, 'Q'
	close, lun
	free_lun, lun
	spawn, 'cat temp.skycalc | skycalc', skycalc_output

	blerg = where(stregex(skycalc_output, 'Then: HA, sec') ge 0)-2
	blarg = where(stregex(skycalc_output, 'Listing done.') ge 0)
	printf, email_lun, 'UPCOMING EVENTS from AZ!'
	for i=blerg[0], blarg[0]-1 do printf, email_lun, skycalc_output[i]
	printf, email_lun, ''
	printf, email_lun, 'CURRENT HOURLY AIRMASS TABLE from AZ!'
	blerg = where(stregex(skycalc_output, 'Local      UT      LMST      HA  ') ge 0)+2
	blarg = where(stregex(skycalc_output, 'Prints geocentric times of repeating phenom') ge 0)
	for i=blerg[0], blarg[0]-1 do printf, email_lun, skycalc_output[i]
				close, email_lun
				free_lun, email_lun

; 	printf, email_lun,skycalc_output[where(stregex(skycalc_output, 'Hourly airmass for') ge 0):where(stregex(skycalc_output, 'Prints geocentric times') ge 0)-1]   
; 	printf, email_lun,skycalc_output[where(stregex(skycalc_output, 'Object RA') ge 0):where(stregex(skycalc_output, 'Listing done') ge 0)-1]   

  spawn, 'cat ' + star_dir + folder + 'email.txt'
;address='zberta@gmail.com'
address='mearthobjectsofinterest@gmail.com'

	if keyword_set(email) then spawn, 'echo "." | mutt -x -s "' +'M.O.I - ' + star_dir + '" -a '+ star_dir +'plots/3lc.pdf -a '+ star_dir +'plots/3lc_candidate_phased.pdf  -i '+star_dir + folder+'email.txt '+ address
	if keyword_set(email) then print, 'just e-mailed a copy to', address
;	endif
END