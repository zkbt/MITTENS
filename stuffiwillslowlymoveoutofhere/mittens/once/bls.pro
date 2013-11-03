
pro counter,num,outof,infostring $
            ,wait_time = waittime $
            ,percent=percent      $
            ,clear=clear $
            ,timeleft=timeleft $
            ,starttime=starttime

;+
; NAME:
;          COUNTER
; PURPOSE:
;          Print a progress status to the screen on a single
;          line. This is WAY cooler than it sounds.
;
; CALLING SEQUENCE:
;          COUNTER, NUMBER, OUTOF  [,INFOSTRING, /PERCENT, WAIT_TIME=variable]
;
; INPUTS:
;          NUMBER:  The current number. Usually the loop index variable
;          OUTOF:   The total number of iterations. The last loop index
;
; OPTIONAL INPUTS:
;
;          INFOSTRING: A string telling the user what is being
;                      counted e.g. 'Flat '
;
; KEYWORD PARAMETERS:
;         
;          PERCENT: Set to output update in percent completed 
;                   percent = rount(number/outof) * 100
;
;          TIMELEFT:  Set to append estimated time remaining.
;          STARTTIME= Used in conjunction w/ /TIMELEFT. Named variable 
;                     that stores the start time of the loop, used for 
;                     calculation of time remaining
;
;          WAIT_TIME:  Used for test and demo purposes only. See
;                      example below.
;
; OUTPUTS:
;          Status is printed to the screen and updated on a single line.
;
; SIDE EFFECTS:
;         This program takes much longer than a simple 
;         print statement. So use COUNTER judiciously. 
;         If your loop consists of only a couple 
;	  of relatively quick commands, updating the 
;	  status with this program could take up a 
;	  significant portion of the loop time!

; PROCEDURE:
;          Put counter statement inside your loop, preferably at the end.
;
; PROCEDURES CALLED:
;            
; EXAMPLE:
;          Try this to see how it works:
;
;          IDL> for i = 0,4 do counter,i,4,'test ',wait=.5
;
;
; MODIFICATION HISTORY:
;      Written by JohnJohn, Berkeley 06 January 2003
;  07-Apr-2008 JohnJohn: Finally fixed /TIMELEFT and STARTTIME keywords
;-
on_error,2
clearline = fifteenb()          ;get "15b character to create a fresh line
if n_elements(infostring) eq 0 then infostring = 'Number ' 
if keyword_set(clear) then begin
    if keyword_set(timeleft) then begin
        timeinit = {t0: systime(/sec), tot: 0.}
        defsysv,'!time',timeinit
        return
    endif else begin
        len = strlen(infostring)
        print,clearline,format='('+strtrim(len,2)+'x, a)'
        return
    endelse
endif 

case 1 of 
    keyword_set(timeleft): begin
        if n_elements(starttime) eq 0 then begin
            starttime = systime(/sec) 
        endif else begin
            tottime = (systime(/sec) - starttime)
            tave = tottime / float(num)
            tleft = sixty((outof-num) * tave/3600.)
            tleft = strjoin(str(fix(tleft),len=2), ':')
            len = strtrim(strlen(strtrim(tleft,2)),2)
            lenst = strtrim(strlen(infostring),2)
            leni = strtrim(strlen(strtrim(num,2)),2)
            leno = strtrim(strlen(strtrim(outof,2)),2)
            form = "($,a"+lenst+",i"+leni+",' of ',i"
            form += leno+",' Estimated time remaining: ',a"+len+",a,a)"
            print, form=form, infostring, num, outof $
                   , tleft, '         ', clearline
        endelse
    end
    keyword_set(percent) : begin
        per = strtrim(round(float(num)*100./outof),2)
        lenp = strtrim(strlen(strtrim(per,2)),2)
        form="($,a"+lenp+",' % Completed',a,a)"
        print, form=form, per, '         ', clearline
    end
    else : begin
        lenst = strtrim(strlen(infostring),2)
        leni = strtrim(strlen(strtrim(num,2)),2)
        leno = strtrim(strlen(strtrim(outof,2)),2)
        form="($,a"+lenst+",i"+leni+",' of ',i"+leno+",a,a)"
        print, form=form, infostring, num, outof, '         ',clearline
    end
endcase
if n_elements(waittime) gt 0 then wait,waittime
end

FUNCTION where_intransit, lc, candidate, n, i_oot=i_oot, buffer=buffer
	if not keyword_set(buffer) then buffer = 0.0
	is_it = bytarr(n_elements(lc))
	i =0  
	if tag_exist(candidate[i], 'PERIOD') then begin
		pad = long((max(lc.hjd) - min(lc.hjd))/candidate[i].period) + 1
		phased_time = (lc.hjd-candidate[i].hjd0)/candidate[i].period + pad + 0.5
		orbit_number = long(phased_time)
		phased_time = (phased_time - orbit_number - 0.5)*candidate[i].period
	endif else phased_time = lc.hjd-candidate[i].hjd0
	      
	is_it = is_it OR (abs(phased_time) lt candidate[i].duration/2.0 + buffer)
	i_it = where(is_it, complement=i_oot, n)
	return, i_it
END    
       
FUNCTION select_peaks, x, n_peaks, pad=pad
	if not keyword_set(n_peaks) then n_peaks=1
	temp = x
	peaks = lonarr(n_peaks)
	if not keyword_set(pad) then pad = 10
	for i=0, n_peaks-1 do begin
		j = where(temp eq max(temp), n)
		peaks[i] = j[0]
		i_nearby = indgen(2*pad) + j[0] - pad
		gauss = mpfitpeak(i_nearby, temp[i_nearby], fit)
		sigma = uint(fit[2])
		     
		;add this - estimate width of line, quintuple it, ignore
		n_sigma = 5
		temp[peaks[i] - n_sigma*sigma > 0:peaks[i]+n_sigma*sigma < (n_elements(temp)-1)] =  0
	endfor
	return, peaks
END    
       
PRO print_candidate, candidate
      print,  '           period = ', strcompress(/remo, string(format='(F9.6)', candidate.period))
      print,  '             hjd0 = ', candidate.hjd0;mjd2hopkinsdate(candidate.hjd0)
      print,  '         duration = ', strcompress(/remov, string(format='(F5.3)', candidate.duration)), ' = ', strcompress(/remo, string(format='(F3.1)', candidate.duration*24)), ' hr'
      print,  'points in transit = ', strcompress(/remo, candidate.n_int)
      print,  '            depth = ', string(format='(F5.3)', candidate.depth)
      print,  '       deltachi^2 = ', strcompress(/remo, string(format='(F10.1)', candidate.chi))
;      print,  '    bootstrap FAP = ', strcompress( candidate.fap)
END    
       
FUNCTION bls, t, relative_flux, relative_flux_error, lc=lc, period_range=period_range, mass=mass, radius=radius, n_peaks=n_peaks, display=display
;+
; NAME:
;	bls 
; PURPOSE:
;	find a planet
; CALLING SEQUENCE:
;	candidates = bls(t, relative_flux, relative_flux_error, lc=lc, period_range=period_range, mass=mass, radius=radius, n_peaks=n_peaks, display=display)
;  INPUTS:
; 	either
; 		t, relative_flux, relative_fluxerr
; 			OR
; 		lc = lc (see comments below for what it needs to look like)
; 
; KEYWORD PARAMETERS:
;	period_range = [minimum_period, maximum_period] that you want to search
; 	mass = stellar mass for duration guess (in solar masses)
; 	radius = stellar mass for duration guess (in solar radii)
;	n_peaks = the number of candidates to spit out, sorted in descending deltachi^2 improvement
;	/display if you want to plot the spectrum
; OUTPUTS:
; 	candidates (a structure)
; RESTRICTIONS:
;
; EXAMPLE:
; 	b = bls(lc=medianed_lc, /display, period_range=[1.55,1.56], n_peaks=5)
; MODIFICATION HISTORY:
;
; 	Last modified by ZKB on 7/01/2011.
;
;-

	if not keyword_set(lc) then begin
		lc = replicate({lightcurve, hjd:0.d, flux:0., fluxerr:0., okay:1B}, n_elements(t))
		lc.hjd = hjd										; hjd could really be any kind of time, in units of days
		lc.flux = -2.5*alog10(relative_flux)					;(the code works in MAGNITUDES. watch out! i.e. positive means fainter!)
		lc.fluxerr = 1.086*relative_flux_error					;(assuming your flux errors are wee)
	endif

	if not keyword_set(mass) then mass = 1.0			; in solar masses
	if not keyword_set(radius) then radius = 1.0			; in solar radii
	if keyword_set(period_range) then begin
		p_min = min(period_range)						; in days
		p_max = max(period_range)						; in days
	endif else begin
		p_min = 1.0
		p_max = 10.0
	endelse
	; the number of candidates to spit out
	if not keyword_set(n_peaks) then n_peaks = 1
	; the number of sub-duration offsets that should be applied
	n_dither = 5
       
	      
	; structure definitions
	temp_candidate = {candidate, period:0.0d, hjd0:0.0d, duration:0.0, chi:0.0, depth:0.0, f:0.0, n_int:0, fap:-1.0}
       
	; plotting stuff
	if keyword_set(display) then begin
		cleanplot, /silent
		if not keyword_set(circle_size) then circle_size=1.0
		theta = findgen(11)/10*2*!pi
		usersym, cos(theta)*circle_size, sin(theta)*circle_size, /fill
	endif 
	      
	; convert to frequency range (inverse days)
	v_min = 1.0d/p_max
	v_max = 1.0d/p_min
	v_bin = 5.0d/60.0/24.0/(max(lc.hjd) - min(lc.hjd))			; intended to phase up to 5 minute precision over the time span of the dataset
	      
	; construct period search array
	n_periods = long((v_max - v_min)/v_bin) + 1
	periods = 1.0/(dindgen(n_periods)*v_bin + v_min)
	a_over_r = 4.2/radius*mass^(1.0/3.0)*periods^(2.0/3.0)	
       
	; use physical information to guess transit duration for each period searched (assumes mid-latitude transit, circular orbit)
	durations = periods/a_over_r/4.0
       
	; define arrays over the periods searched
	it_level = fltarr(n_periods)
	oot_level = fltarr(n_periods)
	deltachi = fltarr(n_periods)
	hjd0s = dblarr(n_periods)
	n_nights = fltarr(n_periods)
	nights = long(lc.hjd)
	n = intarr(n_periods)
	      
	print, 'searching ', strcompress(/remo, n_elements(lc)), ' datapoints and ', strcompress(/remo, n_periods), ' periods from ', string(format='(F4.2)', p_min), ' to ', strcompress(/remo, string(format='(F5.2)', p_max))
       
	for i=0L, n_periods-1 do begin
       
		; set this candidate period + duration
		temp_candidate.period = periods[i]
		temp_candidate.duration = durations[i]
		n_shifts = periods[i]/durations[i]*n_dither
       
		; loop over possible initial event times (this is by far not the fastest way of doing this; there's something clever with histogram(), but it takes too much memory for big data sets)
		for j=0L, n_shifts-1 do begin
			temp_candidate.hjd0 = min(lc.hjd) + j*durations[i]/n_dither
		     
			; select the in-transit points for this candidate
			i_intransit = where_intransit(lc, temp_candidate, n_it)		

			; go to the next period if there were no in-transit points			
			if n_it eq 0 then continue

			; do the calculations
			n[i] = n_it
			weightedsum = total(lc[i_intransit].flux/lc[i_intransit].fluxerr^2, /double)
			inversevarsum = total(1.0/lc[i_intransit].fluxerr^2, /double)
			inversevarsumall = total(1.0/lc.fluxerr^2, /double)
			temp_deltachi = weightedsum*weightedsum/inversevarsum/(1.0d - inversevarsum/inversevarsumall)
			if temp_deltachi gt deltachi[i] then begin
				it_level[i] = weightedsum/inversevarsum/(1.0d - inversevarsum/inversevarsumall)
				oot_level[i] = -weightedsum/inversevarsumall/(1.0d - inversevarsum/inversevarsumall)
				deltachi[i] = weightedsum*it_level[i]
				n_nights[i] = n_elements(uniq(nights[i_intransit]))	
				hjd0s[i] = temp_candidate.hjd0
			endif
		endfor
		counter, i, n_periods, '     periods complete = '
	endfor

	; only look at transits, not antitransits	
	deltachi *= (it_level gt 0)
	i_infinite = where(finite(deltachi, /nan), n_infinite)
	if n_infinite gt 0 then deltachi[i_infinite] = 0.0

	; find the periods that give best deltachis
	peaks = select_peaks(deltachi, n_peaks)

	if keyword_set(display) then begin
		!p.multi=[0,1,2]
		loadct, 39, /silent
		; plot spectrum
		plot, 1.0/periods, deltachi, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('\chi^2 improvement of transit'), yrange=[0, max(deltachi)], xtick_get=xtick_get, ymargin=[4,4], charsize=1
		oplot, 1.0/periods, deltachi, linestyle=1
		axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F7.2)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
		plots, 1.0/periods[peaks[0:n_peaks-1]], deltachi[peaks[0:n_peaks-1]], psym=8, color=250
		i_max = peaks[where(deltachi[peaks] eq max(deltachi[peaks]))]
		; plot spectrum, zoom near peak
		plot, 1.0/periods, deltachi, xstyle=3, xtitle='Frequency (inverse days)', ytitle=goodtex('\chi^2 improvement of transit'), yrange=[0, max(deltachi)], xtick_get=xtick_get, ymargin=[4,4], charsize=1, xrange=([-0.01, 0.01] + 1/periods[i_max[0]])
		oplot, 1.0/periods, deltachi, linestyle=1
		axis, xaxis=1, xtickv=xtick_get, xtickn=strcompress(/remove_all, string(format='(F9.4)', 1.0/xtick_get)), xticks=n_elements(xtick_get)-1, xtitle='Period (days)', charsize=1
		plots, 1.0/periods[peaks[0:n_peaks-1]], deltachi[peaks[0:n_peaks-1]], psym=8, color=250
		i_max = peaks[where(deltachi[peaks] eq max(deltachi[peaks]))]
	endif

	; store the information from the peaks as candidate structures
	for j=0, n_peaks -1 do begin
		i = peaks[j]
		this = {candidate}
		this.period = periods[i]
		this.hjd0 = hjd0s[i]
		this.duration = durations[i]
		i_intransit = where_intransit(lc, this, i_oot=i_oot, n_it)
		weightedsum = total(lc[i_intransit].flux/lc[i_intransit].fluxerr^2, /double)
		this.chi = weightedsum*it_level[i]
		this.n_int = n[i]
		this.depth = it_level[i]
		if n_elements(candidates) eq 0 then candidates = this else candidates = [candidates, this]
	endfor

	; print out the candidates to the screen
	print, ' '
	print, ' '
	; save the whole session to a file
	save, filename='bls_session.idl'
	print, 'saved this bls search session to bls_session.idl; please restore to play with the arrays!'

	for i =0, n_elements(candidates)-1 do begin
		print, ' '
		print, ' '
		print_candidate, candidates[i]
	endfor


	return, candidates
END