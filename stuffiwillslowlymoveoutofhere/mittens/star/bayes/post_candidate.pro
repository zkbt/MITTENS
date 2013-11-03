PRO post_candidate, note, dead=dead
  common this_star
  @constants

	restore, star_dir + 'cleaned_lc.idl'
; 	if n_elements(candidate) eq 0 then begin
; 		restore, star_dir + 'candidates_pdf.idl'
; 		print_struct, best_candidates
; 		which=question(/number, /int, 'which candidate would you like to explore?')
; 		candidate=best_candidates[which]
; 	endif

	restore, star_dir() + 'box_pdf.idl'
	cleanplot
	plot_boxes, boxes, candidate=candidate, /eps, /png, red_variance=box_rednoise_variance

	restore, star_dir + 'jmi_file_prefix.idl'
	cleanplot
	lc_plot, /eps, /png
	lc_plot, /diag, /eps, /png
	lc_plot, /diag, /phase, /eps, /time, /png
	lc_plot, /time, /eps, /png
	lc_plot, /time, /phase, /eps, /png



	combined = strmatch(star_dir, '*combined*')
	
	; make master image
	if ~keyword_set(combined) and ~strmatch(!version.os, 'darwin') then begin
		if file_test(star_dir() + 'master_field_image.png') then file_delete, star_dir() + 'master_field_image.png'
		load_image, save_image=star_dir + 'master_field_image.png', /master, pixels=600
	endif


  ; a text file that will e-mailed
  openw, email_lun, /get_lun, star_dir + 'post.txt'


  ; tags for the observations
  tel_string=stregex(/ex, star_dir, 'te[0-9]+')
  lspm_string=stregex(/ex, star_dir, 'ls[0-9]+')
lspm = long(stregex(/ex, lspm_string, '[0-9]+'))
  year_string=stregex(/ex, star_dir, 'ye[0-9]+')
extra_label =  stregex(/ex, star_dir, 'ye[0-9]+/te[0-9]+')
  tags=[tel_string, lspm_string, year_string]

if keyword_set(combined) then tags = [tags, 'combined']

  if keyword_set(combined) then begin
	f = stregex(/ex, file_search(lspm_string + '/*/*/box_pdf.idl'), 'ye[0-9]+/te[0-9]+')
	extra_label = f[0]
	for i=1, n_elements(f)-1 do extra_label += ','+ f[i]
endif
  ; set the title
  period_string= rw(string(candidate.period, format ='(D12.2)')) + ' days'  
  depth_string=rw(string(candidate.depth^0.5*lspm_info.radius*r_solar/r_earth, format ='(D6.1)')) +  ' Earth'
  significance_string= rw(string(candidate.depth/candidate.depth_uncertainty, format ='(D5.1)')) + ' sigma'
  if keyword_set(dead) then title_string = lspm_string + ' | ' + ' is no longer interesting' else title_string=lspm_string + ' | ' + period_string + ', ' + depth_string + ', ' + significance_string + ' | ' + '('+extra_label+')'
  printf, email_lun, '[title ', title_string,']'
  
	if keyword_set(note) then printf, email_lun, note + '<p>'


  i_intransit=where_intransit(cleaned_lc, candidate, n_intransit)
  if n_intransit gt 0 then begin
    transit_number=round((cleaned_lc[i_intransit].hjd - candidate.hjd0)/candidate.period)
    unique_transit_number=transit_number[uniq(transit_number, sort(transit_number))]
  endif
 n_transits = n_elements(unique_transit_number)
	  ; tags for the number of observations
  	benchmarks=[0, 50, 100, 200, 400, 1000, 2000, 10000,100000]
	i=value_locate(benchmarks, n_elements(cleaned_lc))
	ndata_string=rw(benchmarks[i]) + ' - ' + rw(benchmarks[i+1]) + ' datapoints'
	tags=[tags, ndata_string]

	  ; tags for the number of transits
	if n_transits eq 1 then ntransits_string = '1 transit'
	if n_transits eq 2 then ntransits_string = '2 transits'
	if n_transits ge 3 then ntransits_string = '>3 transits'
	tags=[tags, ntransits_string]

	  ; tags for the number of observations
  	benchmarks=[0, 1, 2, 5, 10, 20, 50]
	i=value_locate(benchmarks,candidate.period)
	nperiod_string=rw(benchmarks[i]) + ' - ' + rw(benchmarks[i+1]) + ' days'
	tags=[tags, nperiod_string]
; 

	  ; tags for the number of observations
  	benchmarks=[0, 5, 6, 7,10,20,50,100]
	i=value_locate(benchmarks,candidate.depth/candidate.depth_uncertainty)
	nsig_string='S/N is ' +rw(benchmarks[i]) + ' - ' + rw(benchmarks[i+1]) 
	tags=[tags, nsig_string]


    pos_string=''
    openr, lun, star_dir + '/pos.txt', /get_lun
    readf, lun, pos_string, format='(A100)'
    close, lun
    free_lun, lun
if ~keyword_set(combined) then begin
	restore, star_dir + 'field_info.idl'
	iflux =  string(format='(F4.1)', info_target.medflux)
endif else iflux = '??'

flwo_cat, lspm, flwo_string



        ecc=0.0
        sini=1.0
        planet_radius=candidate.depth^0.5*lspm_info.radius*r_solar
        planet_density=2.0
        planet_mass=planet_density*4*!pi/3.0*planet_radius^3
        k=planet_mass*sini/sqrt(1-ecc^2)*(2*!pi*g/(candidate.period*day)/(lspm_info.mass*m_sun)^2)^(1.0/3.0)


        printf, email_lun,  '<code>P= ', rw(string(candidate.period, format ='(D12.9)')), ' days, HJDo = ', string(candidate.hjd0+2400000.5d, format ='(D14.6)'), ' = ', string(candidate.hjd0, format ='(D12.6)'), ' (modified)', '<br>',  '   duration=', string(candidate.duration, format ='(D5.3)'), '=',  string(candidate.duration*24, format ='(D4.2)') + ' hours', ', depth=', string(candidate.depth, format ='(D6.4)'), '=', rw(string(candidate.depth^0.5*lspm_info.radius*r_solar/r_earth, format ='(D6.1)')), ' Earth', '<br>','   S/N=', rw(string(candidate.depth/candidate.depth_uncertainty, format ='(D5.1)')), ', ', rw(candidate.n_boxes), ' events, ',  rw(candidate.n_points), ' in-transit observations[more]'
        printf, email_lun,  '<code>   RV semiamplitude=', strcompress(/remo, string(format='(F5.1)', k/100)), ' m/s (for a density of 2 g/cc)'
        teq=lspm_info.teff*(0.5/a_over_rs(lspm_info.mass, lspm_info.radius, candidate.period))^0.5
        printf, email_lun,  '<code>   a/R*=', rw(string(format='(F5.1)', a_over_rs(lspm_info.mass, lspm_info.radius, candidate.period)) ), ', equilibrium temperature=', strcompress(/remo, string(format='(I10)', teq)) , 'K (for zero albedo)' 
	printf, email_lun, ' '

      printf, email_lun, '<code>',flwo_string, '<br>   px=', string(format='(F5.3)', lspm_info.parallax), ' +/- ', string(format='(F5.3)', lspm_info.err_parallax), ',  pm=', strcompress(string(format='(F5.2)', lspm_info.pmra)), ' ', string(format='(F5.2)', lspm_info.pmdec), '<br>',$
      '   V=', string(format='(F4.1)', lspm_info.v),', I=',iflux,', J=', string(format='(F4.1)', lspm_info.j), ', H=', string(format='(F4.1)', lspm_info.h), ', K=', string(format='(F4.1)', lspm_info.k), '<br>',$
       '   mass=', string(lspm_info.mass, format='(F4.2)'), ', radius=', string(lspm_info.radius, format='(F4.2)'), ', teff=', string(lspm_info.teff, format='(I4)'), '<br>',$
	'   '+jmi_file_prefix

    	printf, email_lun
    ;   printf, email_lun,  '   ratio=', string(candidate.chi/max(-big_bls[1,*].chi), format ='(D4.1)')
;         printf, email_lun,  '   f=', string(candidate.f, format ='(D4.2)')
;         printf, email_lun,  '   fap=', strcompress(/remo, string(candidate.fap, format='(G10.4)'))

printf, email_lun, ''
; 
; printf, email_lun, '[more]'
; 
; 
  openw,  lun,'temp.skycalc', /get_lun
  printf, lun, 'h'
  spaces=strsplit(pos_string)
  printf, lun,'r ', strmid(pos_string, spaces[0], spaces[1]-1)
  printf, lun, 'd ', strmid(pos_string, spaces[1], 1000)
  printf, lun, 'h'
  printf, lun, star_dir
  printf, lun, 'xv'

	printf, lun, candidate.period, format='(D20.10)'
	if n_intransit gt 0 then printf, lun, candidate.duration/max(unique_transit_number) else printf, lun, 1000.0
	printf, lun,  candidate.hjd0+2400000.5d , format='(D15.6)'
	printf, lun, candidate.duration/2.0

  caldat, systime(/julian), month, day, year
  printf, lun, string(format='(I4)', year) + ' ' + string(format='(I2)', month) + ' ' + string(format='(I2)', day)
  caldat, systime(/julian)+30, month, day, year
  printf, lun,  string(format='(I4)', year) + ' ' + string(format='(I2)', month) + ' ' + string(format='(I2)', day)
  printf,  lun, '-1'
  printf,  lun, '90'
  printf, lun, 'Q'
  close, lun
  free_lun, lun
  spawn, 'cat temp.skycalc | skycalc', skycalc_output

  blerg=where(stregex(skycalc_output, 'Then: HA, sec') ge 0)-2
  blarg=where(stregex(skycalc_output, 'Listing done.') ge 0)
  printf, email_lun, '','UPCOMING EVENTS from AZ!'
str =''
  for i=blerg[0], blarg[0]-1 do str+='<code>'+ skycalc_output[i]+ '<br>'
printf, email_lun, str
  printf, email_lun, ''
  printf, email_lun, 'HOURLY AIRMASS TABLE from AZ!'
  blerg=where(stregex(skycalc_output, 'Local      UT      LMST      HA  ') ge 0)+2
  blarg=where(stregex(skycalc_output, 'Prints geocentric times of repeating phenom') ge 0)
str =''
printf, email_lun, '<code>'+ skycalc_output[blerg[0]-2]+ '<br>'
  for i=blerg[0], blarg[0]-1 do str+='<code>'+ skycalc_output[i]+ '<br>'
printf, email_lun, str
printf, email_lun, ''
; 

tag_string = '[tags ' + tags[0]
for i=1, n_elements(tags)-1 do tag_string += ', '+tags[i]
tag_string += ']'
printf, email_lun, tag_string
if keyword_set(dead) then printf, email_lun, '[category No Longer]' else printf, email_lun, '[category Act]'

        close, email_lun
        free_lun, email_lun
; 
; ;   printf, email_lun,skycalc_output[where(stregex(skycalc_output, 'Hourly airmass for') ge 0):where(stregex(skycalc_output, 'Prints geocentric times') ge 0)-1]   
; ;   printf, email_lun,skycalc_output[where(stregex(skycalc_output, 'Object RA') ge 0):where(stregex(skycalc_output, 'Listing done') ge 0)-1]   
; 
   spawn, 'cat ' + star_dir + 'post.txt'
;address='zberta@gmail.com'
address='duya769zazi@post.wordpress.com'
wait, 2
prefix =  star_dir + lspm_string+'_'+tel_string +'_'
files = file_search(star_dir + 'plots/*.png')
if ~keyword_set(combined) then files = [files, star_dir + 'master_field_image.png']
files_to_attach = ''
if files[0] ne '' then begin
	for i = 0, n_elements(files)-1 do begin
		info = file_info(files[i])
		; was it made in the past couple of hours?
		if info.mtime - systime(/sec) lt 60*60*2 then begin
			if strmatch(info.name, '*prediction*png') eq 0 then begin
				file_move, info.name, prefix + stregex(info.name, '[^/]+.png', /ext), /over
				files_to_attach += ' -a ' + prefix + stregex(info.name, '[^/]+.png', /ext)
			endif
		endif
	endfor
endif
command =  'echo "." | mutt -x -s "' +title_string+ '"'+$
		files_to_attach
;if ~keyword_set(combined) then command += ' -a ' + star_dir + 'master_field_image.png' 
command += ' -i '+star_dir +'post.txt '+ address
print, command
		spawn, command
; address='mearthobjectsofinterest@gmail.com'
; 
;   if keyword_set(email) then spawn, 'echo "." | mutt -x -s "' +'M.O.I - ' + star_dir + '" -a '+ star_dir +'plots/3lc.pdf -a '+ star_dir +'plots/3lc_candidate_phased.pdf  -i '+star_dir + folder+'email.txt '+ address
;   if keyword_set(email) then print, 'just e-mailed a copy to', address
;   

;   
;   
END