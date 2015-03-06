FUNCTION trim_lc, fitsname, n_sigma=n_sigma, n_trim=n_trim, pause=pause, show_plot=show_plot, eps_path=eps_path, flags_to_check=flags_to_check, star=star, bad_obs_path=bad_obs_path
	
	; trim_lc.pro
	; by zach
	; 9-march-2009
	;
	; this function reads in a MEarth lightcurve file, trims off those observations which 1) contain more than n_trim
	; n_sigma outliers 2) are flagged a having been on bad pixels, etc... or 3) list the target flux as NaN,
	; and returns a structure containing the MEarth target photometry on either side of the meridian flip 
	; (unless the keyword 'star' is set to the index of another star in the field for which photometry is
	; desired). 
	;
	; fitsname =		full path of .fits file to open
	; n_sigma = 		number of 1.48 MAD's to consider a point an outlier (default 3)
	; n_trim = 			number of outliers to consider an observation bad (default 3)
	; pause = 			number of seconds to pause after plotting (useful if you'd like to look at many LCs in a row)
	; /show_plot 		show the relevant plots
	; eps_path = 		path in which to save a .eps version of the plot
	; flags_to_check =	which flags to use for target rejection	(default [1,2])
	; star = 			index of another star in the field, if you want photometry on something other than the target
	;					(set to -42 to return all comparisons!)
	; bad_obs_path = 	string containing the bad where the indices of the bad observations should be saved
	;
	; return value:
	;	{east:(lightcurve structure for the east side of the meridian),
	;	 west:(ditto on the west),
	;	 rms:(target rms [(east side before trim), (west side before trim), (east side after trim), (west side after trim)])}
	;
	; warning: will act a bit dodgy if you give a lightcurve with fewer than n_trim comparison stars or with very few time points,
	;			but hopefully shouldn't freak out and freeze up
	;
	; any questions, please ask!
	
	print, ''
	print, 'LIGHTCURVE TRIM-O-MATIC'

	; set things that need to be set if they're not already set
	if not keyword_set(n_sigma) then n_sigma = 3
	if not keyword_set(n_trim) then n_trim = 0.2
	if not keyword_set(flags_to_check) then flags_to_check = [1,2]
	bad_obs = -1

	; make plotting look nice
	!p.charsize=1.0
	!p.symsize=0.2
	!p.thick=1
	erase
	max_rows = 20
	loadct, 39, /silent
	do_plot = keyword_set(show_plot) or keyword_set(eps_path)
	
	; read in lightcurve FITS file
	f = mrdfits(fitsname, 1, h, status=status, /silent)
	print, '   | reading ', fitsname
	
	; make sure the FITS was read well
	if (status ge 0) then begin
		print, '        the FITS file was successfully read'
		print, '   | preparing to trim:'
		print, '        the points that have ', string(n_trim, format='(I3)'), ' or more ',string(n_sigma, format='(I3)'), ' sigma outliers amongst the comparison stars' 
		print, '        the points with target values of NaN'
		print, '        the points flagged as', flags_to_check
		
		; open an .EPS output for the plot, if needed
		if keyword_set(eps_path) then begin
			set_plot, 'ps'
			device, filename=eps_path + sxpar(h, 'OBJECT') + '_trims.eps'	, /color, /encapsulated, /inches, xsize=7.5, ysize=10
		endif
		
		fits_tags = tag_names(f)
		j_m = where(fits_tags eq 'J_M', n_J)
		
		; define indices for the M dwarf (target) and the companion stars of similar brightness (friends)
		i_target = where(f.class eq 9, n_target)	
		i_target = i_target[0]
		if n_target gt 0  and n_J gt 0 then begin
			n_obs_in_lc = n_elements(f[i_target].hjd)
			upper_mag_limit = f[i_target].medflux -1 ;sxpar(h, 'UMLIM')
			lower_mag_limit = upper_mag_limit + 2
			i_friends = where(f.class eq -1 and f.medflux ge upper_mag_limit and f.medflux le lower_mag_limit and median(f.weight,dimension=1) gt 0, n_friends)
			print, '    | there are ', n_friends, ' appropriate comparison stars'	
	
			; if there are enough comparison stars to potentially satisfy the trim conditions, continue
			if (n_friends ge max([n_trim*n_friends, 2])) then begin	
			
				; set up a matrix of plots with two columns (east and west of meridian) and the necessary number of rows
				n_rows = min([n_friends+1, max_rows])
				if do_plot then multiplot, /init, [0,2, n_rows, 0, 1]
			
				; look first at all observations taken on the east side of the meridian
				j_east = where(f[i_target].ha lt 0, n_east)
				print, '   | the east side of the meridian has ', n_east, ' out of ', n_obs_in_lc, ' total observations'
				
				; if there are observations on the east side, trim them!
				if (n_east gt 1) then begin	


					; a vector containing the median flux for each friend
					medflux_east = median(f[i_friends].flux[j_east], dimension=1)
					
					; a matrix containing (flux - median) for each friend's lightcurve
					flux_east = f[i_friends].flux[j_east] - (fltarr(n_east) + 1.0)#medflux_east
				
					; a matrix containing the weight with which each point was used to calculate the differential photometry
					weight_east = f[i_friends].weight[j_east]
				
					; a vector containing the robust scatter estimate for each friend
					scatter_east = 1.48*median(abs(flux_east), dimension=1)
				
					; a matrix showing containing a 0 for good data and 1 for outlying points 
					east_bad = abs(flux_east/((fltarr(n_east) + 1.0)#scatter_east)) gt n_sigma and f[i_friends].weight[j_east] gt 0 or finite(flux_east, /nan)

					; a vector containing 1 for bad observations and 0 for good observations (and its complement)
 					east_trim = (total(east_bad, 2) ge n_trim*n_friends) or $
 								(finite(f[i_target].flux[j_east], /nan) ne 0) or $
 								(is_flagged(f[i_target].flags[j_east], flags_to_check, /print_result) gt 0)
     				east_keep = (total(east_bad, 2) lt n_trim*n_friends) and $
     							(finite(f[i_target].flux[j_east], /nan) eq 0) and $
     							(is_flagged(f[i_target].flags[j_east], flags_to_check) eq 0)
  					print, '        ', string(total(east_trim), format='(I)'), ' of them have been trimmed'
					
					; plot the target star
					if do_plot then multiplot
					if do_plot then plot, f[i_target].flux[j_east] - f[i_target].medflux, psym=5, /yno, title=sxpar(h,'OBJECT');+','+string(tel, format='(I1)')
					if (total(east_trim)) then begin
						if do_plot then oplot, where(east_trim),   +f[i_target].flux[j_east[where(east_trim)]] - f[i_target].medflux, psym=5, color=250
						bad_obs = [bad_obs, j_east[where(east_trim)]]
					endif
					
					; determine the RMS for the target star before and after trim
					rms_before_east = stddev(f[i_target].flux[j_east] - f[i_target].medflux, /nan)
					if (total(east_keep) gt 1) then begin
							rms_after_east = stddev(f[i_target].flux[j_east[where(east_keep)]] - f[i_target].medflux, /nan)
					endif	

					; plot the comparison stars
					if do_plot then begin
						for i=0, n_rows-2 do begin
							if (total(finite(flux_east[*,i])) gt 2) then begin
								multiplot & plot, flux_east[*,i], psym=1, /yno
								i_zeroweight = where(weight_east[*,i] le 0, n_zeroweight)
								if (n_zeroweight) then oplot, i_zeroweight, flux_east[i_zeroweight,i], psym=1, color=190
								if (total(east_bad[*,i])) then oplot,where(east_bad[*,i]), flux_east[where(east_bad[*,i]), i], psym=1, color=250
								legend, string(i_friends[i], format='(I5)'), /right, box=0
							endif
						endfor
					endif
				
					; make a new structure to contain the trimmed target information
					if keyword_set(star) then star_include = star else star_include=i_target
					loop = 1
					if keyword_set(star) then if star eq -42 then begin
						star_include = i_friends
						star_include = [i_target, star_include]
						loop = n_elements(star_include)
					endif	
					if (total(east_keep) gt 0) then begin
						for q=0, loop-1 do begin
							temp_east={ hjd:f[star_include[q]].hjd[j_east[where(east_keep)]], $
										flux:f[star_include[q]].flux[j_east[where(east_keep)]], $
										fluxerr:f[star_include[q]].fluxerr[j_east[where(east_keep)]], $
										xlc:f[star_include[q]].xlc[j_east[where(east_keep)]], $
										ylc:f[star_include[q]].ylc[j_east[where(east_keep)]], $
										airmass:f[star_include[q]].airmass[j_east[where(east_keep)]], $
										ha:f[star_include[q]].ha[j_east[where(east_keep)]], $
										weight:f[star_include[q]].weight[j_east[where(east_keep)]], $
										flags:f[star_include[q]].flags[j_east[where(east_keep)]], $
										pointer:f[star_include[q]].pointer, $ 
										medflux:f[star_include[q]].medflux, $
										x:f[star_include[q]].x, $
										y:f[star_include[q]].y, $
										j_m:f[star_include[q]].j_m, $
										h_m:f[star_include[q]].h_m, $
										k_m:f[star_include[q]].k_m}
							if (q eq 0) then target_east = temp_east else target_east = [target_east,temp_east]
						endfor
					endif
				endif
				
				; repeat for all observations taken on the west side of the meridian
				j_west = where(f[i_target].ha gt 0, n_west)
				print, '   | the west side of the meridian has ', n_west, ' out of ', n_obs_in_lc, ' total observations'
				
				; if there are observations on the west side, trim them!
				if (n_west gt 1) then begin	

     
     				; a vector containing the median flux for each friend
     				medflux_west = median(f[i_friends].flux[j_west], dimension=1)
     				
     				; a matrix containing (flux - median) for each friend's lightcurve
     				flux_west = f[i_friends].flux[j_west] - (fltarr(n_west) + 1.0)#medflux_west
     				
     				; a matrix containing the weight with which each point was used to calculate the differential photometry
     				weight_west = f[i_friends].weight[j_west]
     				
     				; a vector containing the robust scatter estimate for each friend
     				scatter_west = 1.48*median(abs(flux_west), dimension=1)
     				
     				; a matrix showing containing a 0 for good data and 1 for outlying points 
     				west_bad = abs(flux_west/((fltarr(n_west) + 1.0)#scatter_west)) gt n_sigma and f[i_friends].weight[j_west] gt 0 or finite(flux_west, /nan)
     	
     				; a vector containing 1 for bad observations and 0 for good observations (and its complement)
  					west_trim = (total(west_bad, 2) ge n_trim*n_friends) or $
 								(finite(f[i_target].flux[j_west], /nan) ne 0) or $
 								(is_flagged(f[i_target].flags[j_west], flags_to_check, /print_result) gt 0)
     				west_keep = (total(west_bad, 2) lt n_trim*n_friends) and $
     							(finite(f[i_target].flux[j_west], /nan) eq 0) and $
     							(is_flagged(f[i_target].flags[j_west], flags_to_check) eq 0)
     				print, '        ', string(total(west_trim), format='(I)'), ' of them have been trimmed'
     
     				; plot the target star
     				if do_plot then multiplot
     				if do_plot then plot, f[i_target].flux[j_west] - f[i_target].medflux, psym=5, /yno, title=sxpar(h,'OBJECT');+','+string(tel, format='(I1)')
     				if (total(west_trim)) then begin
     					if do_plot then oplot, where(west_trim),   +f[i_target].flux[j_west[where(west_trim)]] - f[i_target].medflux, psym=5, color=250
     					bad_obs = [bad_obs, j_west[where(west_trim)]]
     				endif
     				
     				; determine the RMS for the target star before and after trim
     				rms_before_west = stddev(f[i_target].flux[j_west] - f[i_target].medflux, /nan)
     				if (total(west_keep) gt 1) then begin
     						rms_after_west = stddev(f[i_target].flux[j_west[where(west_keep)]] - f[i_target].medflux, /nan)
     				endif
     
     				; plot the comparison stars
     				if do_plot then begin
     					for i=0, n_rows-2 do begin
     						if (total(finite(flux_west[*,i])) gt 2) then begin
     							multiplot & plot, flux_west[*,i], psym=1, /yno
     							axis, yaxis=1
     							i_zeroweight = where(weight_west[*,i] le 0, n_zeroweight)
     							if (n_zeroweight) then oplot, i_zeroweight, flux_west[i_zeroweight,i], psym=1, color=190
     							if (total(west_bad[*,i])) then oplot,where(west_bad[*,i]), flux_west[where(west_bad[*,i]), i], psym=1, color=250
     							legend, string(i_friends[i], format='(I5)'), /right, box=0
     						endif
     					endfor
     				endif
     			
					; make a new structure to contain the trimmed target information
					if keyword_set(star) then star_include = star else star_include=i_target
					loop = 1
					if keyword_set(star) then if star eq -42 then begin
						star_include = i_friends
						star_include = [i_target, star_include]
						loop = n_elements(star_include)
					endif	
					if (total(west_keep) gt 0) then begin
						for q=0, loop-1 do begin
							temp_west={ hjd:f[star_include[q]].hjd[j_west[where(west_keep)]], $
										flux:f[star_include[q]].flux[j_west[where(west_keep)]], $
										fluxerr:f[star_include[q]].fluxerr[j_west[where(west_keep)]], $
										xlc:f[star_include[q]].xlc[j_west[where(west_keep)]], $
										ylc:f[star_include[q]].ylc[j_west[where(west_keep)]], $
										airmass:f[star_include[q]].airmass[j_west[where(west_keep)]], $
										ha:f[star_include[q]].ha[j_west[where(west_keep)]], $
										weight:f[star_include[q]].weight[j_west[where(west_keep)]], $
										flags:f[star_include[q]].flags[j_west[where(west_keep)]], $
										pointer:f[star_include[q]].pointer, $ 
										medflux:f[star_include[q]].medflux, $
										x:f[star_include[q]].x, $
										y:f[star_include[q]].y, $
										j_m:f[star_include[q]].j_m, $
										h_m:f[star_include[q]].h_m, $
										k_m:f[star_include[q]].k_m}
							if (q eq 0) then target_west = temp_west else target_west = [target_west,temp_west]
						endfor
					endif
     			endif
     			
     			if keyword_set(pause) then wait, pause
     			multiplot, /default
     
     			; determine which observations are 'BAD', for diagnostic plot purposes
     			if (n_elements(bad_obs)) then bad_obs = bad_obs[sort(bad_obs)]
     			
     		endif		
     		
     		if keyword_set(eps_path) then begin
     			device, /close
     			set_plot, 'x'
     			print, '   | an eps plot output to ', eps_path
     		endif
     
     		object = sxpar(h,'OBJECT')
     		mjd = sxpar(h, 'TV*') + sxpar(h, 'MJDBASE') - sxpar(h, 'EXPTIME')/2.0/24.0/60.0/60.0
     		if (n_elements(bad_obs) gt 1) then mjd_bad_obs = mjd[bad_obs[1:*]] else mjd_bad_obs = -1
     		
     		if keyword_set(bad_obs_path) then begin
     			save, mjd_bad_obs, object, n_obs_in_lc, filename=bad_obs_path + object + '_is_bad.idl'		
     		endif
		endif else print, '      no target was found in the FITS file!'
	endif else print, '        there was an error reading the FITS file'
	
	; make sure the these values are defined
	if not keyword_set(rms_before_east) then rms_before_east = [-1]
	if not keyword_set(rms_after_east) then rms_after_east = [-1]
	if not keyword_set(rms_before_west) then rms_before_west = [-1]
	if not keyword_set(rms_after_west) then rms_after_west = [-1]	
	if not keyword_set(target_east) then target_east = -1
	if not keyword_set(target_west) then target_west = -1
	if not keyword_set(object) then object = -1
	
	
	
	rms = [rms_before_east, rms_before_west, rms_after_east, rms_after_west]
	print, ''
	return, {east:target_east, west:target_west, rms:rms, object:object}
END