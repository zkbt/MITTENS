FUNCTION gamma_pdf, x, k, theta
	return, 1.0/theta^k/gamma(k)*x^(k-1)*exp(-x/theta)
END

FUNCTION integral_of_gamma_pdf, x_max,k, theta
	x = findgen(100)/100*x_max
	return, int_tabulated(x, gamma_pdf(x, k, theta))
END

FUNCTION spot_amplitude_pdf, x, inc, typical_edge_on_spot_amplitude, f_nospots
	; calibrated off "tilt_stars.pro", assuming 10 randomly oriented spots on the star, and calling the stddev of the spot curve the "amplitude"

	if keyword_set(typical_edge_on_spot_amplitude) then begin
		k90 =  2.10670 + (!pi/2.0)*0.758971 + (!pi/2.0)^2*1.88888 + (!pi/2.0)^3*(-0.819710)
		theta90 = -0.000134982 + (!pi/2.0)* 0.0156005 + (!pi/2.0)^2*(-0.0139268)+ (!pi/2.0)^3*0.00386050
		scale_factor = typical_edge_on_spot_amplitude/(k90-1)/theta90
	endif else scale_factor = 1.0

	k = 2.10670 + inc*0.758971 + inc^2*1.88888 + inc^3*(-0.819710)
	theta =( -0.000134982 + inc* 0.0156005 + inc^2*(-0.0139268)+ inc^3*0.00386050)*scale_factor > 0.00001
;	print, k, theta
	if ~keyword_set(f_nospots) then f_nospots = 0.0
;	if x[1] ne 0.000500000 then  stop
	return, (gamma_pdf(x, k, theta))*(1.0-f_nospots) + f_nospots*(x lt 0.005)/0.005
END

FUNCTION isotropic_spots_pdf, x, typical_edge_on_spot_amplitude, f_nospots
	inc = findgen(91)*!pi/180.0
	p = dblarr(n_elements(x))
	dinc = inc[1] - inc[0]
	for i=0, n_elements(inc)-1 do begin
		p += spot_amplitude_pdf(x, inc[i], typical_edge_on_spot_amplitude, f_nospots)*sin(inc[i])*dinc
	endfor
;	if x[1] eq 0.000100000 then	print, 'angle integrated = ', int_tabulated(x, p)
	return, p
	;return, p
END

PRO model_mearth_spots, eps=eps

	restore, 'ensemble_of_rough_fits.idl'
	
	xplot
	loadct, 39
	i_all = where(r.summary_sin.dof gt 500 )
	amps_in_sample =  r[i_all].amp
	i_robust = where(r.summary_sin.dof gt 500 and r.summary_sin.rescaling + 2*r.summary_sin.uncertainty_in_rescaling lt r.summary_flat.rescaling )
	i_abovehalfpercent = where(r.summary_sin.dof gt 500 and r.summary_sin.rescaling + 2*r.summary_sin.uncertainty_in_rescaling lt r.summary_flat.rescaling and r.amp gt 0.005 )
	res =100
	x_axis = findgen(5000)*0.00001


			plothist, r[i_all].amp, bin=0.001, xr=[0.0, 0.05]
			plothist, r[i_robust].amp, bin=0.001, /overplot, color=250
			plothist, r[i_abovehalfpercent].amp, bin=0.001, /overplot, color=60
			oplot, x_axis, isotropic_spots_pdf(x_axis,0.005, 0.25), thick=3

if question('asdg', int=int) then stop

; 	b = randomu(seed, 10000)
; 	inclinations = acos(b)


;	oplot, x_axis, isotropic_spots_pdf(x_axis, 0.02, 0.1)
	int = 1
if question('asdg', /int) then stop
	typical_edge_on_spot_amplitudes = findgen(res)/res*0.02 + 0.002
	nospot_fractions = (findgen(res/4))/res*4
	loglike = dblarr(res,res/4)
	integral = dblarr(res,res/4)

	for i=0, n_elements(typical_edge_on_spot_amplitudes)-1 do begin
		if keyword_set(eps) and i eq n_elements(typical_edge_on_spot_amplitudes)-1 then begin
			set_plot, 'ps'
			file_mkdir, 'spots'
			device, filename='spots/modelling_mearth_spots.eps', /color, /inches, xsize=8, ysize=5, /encap
		endif

		for j=0, n_elements(nospot_fractions) -1 do begin

		;	integral[i,j] =  int_tabulated(x_axis, isotropic_spots_pdf(x_axis, typical_edge_on_spot_amplitudes[i], nospot_fractions[j]))
			perpoint = -alog(isotropic_spots_pdf( amps_in_sample, typical_edge_on_spot_amplitudes[i], nospot_fractions[j]))
			loglike[i,j] = total(perpoint)


		endfor

		i_best = where(loglike[0:i-1,*] eq min(loglike[0:i-1,*]), n_best)
		i_best = i_best[0]
		ai = array_indices(loglike[0:i-1,*], i_best)
		best_edgeon = typical_edge_on_spot_amplitudes[ai[0]]
		best_nospot = nospot_fractions[ai[1]]
	;	if keyword_set(int) then begin
				!p.multi=[0,1,3]
				plothist, r[i_all].amp, bin=0.001, xr=[0.0, 0.05]
				plothist, r[i_robust].amp, bin=0.001, /overplot, color=250
				plothist, r[i_abovehalfpercent].amp, bin=0.001, /overplot, color=60
				oplot, x_axis, isotropic_spots_pdf(x_axis, best_edgeon,best_nospot)*0.001*n_elements( r[i_all].amp), thick=3
	;			plot, amps_in_sample, perpoint, psym=1, xr=[0.0, 0.05]
				al_legend, ['amp = ' + string(best_edgeon), 'f = ' + string(best_nospot)], /righ, box=0
	;	endif
		contour, loglike, typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=100, xtitle='Typical Spot Amplitude for an Edge on Star', ytitle='Fraction of Stars with No Spots', xs=3, ys=3

		contour, exp((-loglike + min(loglike))), typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=100, xtitle='Typical Spot Amplitude for an Edge on Star', ytitle='Fraction of Stars with No Spots', xs=3, ys=3 
;		contour, integral, typical_edge_on_spot_amplitudes, nospot_fractions, /fill, nlevels=40, xtitle='Typical Spot Amplitude for an Edge on Star', ytitle='Fraction of Stars with No Spots', xs=3, ys=3
		if keyword_set(eps) and i eq n_elements(typical_edge_on_spot_amplitudes)-1 then begin
			device, /close
			set_plot, 'x'
			epstopdf, 'spots/modelling_mearth_spots.eps'
		endif
	endfor
	save, filename='exploring_population_spots.idl'
stop


END