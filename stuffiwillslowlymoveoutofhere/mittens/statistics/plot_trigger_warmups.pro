PRO	plot_trigger_warmups, year=year, nstars=nstars, eps=eps, maxrednoise=maxrednoise
	if ~keyword_set(year) then year = 11
	if ~keyword_set(nstars) then nstars = 50
	cloud= compile_fake_triggers(year=year, nstars=nstars)
		duration_min = 1.0/24.0
	if ~keyword_set(maxrednoise) then maxrednoise=1000;max(cloud.recovered.rednoise)
	common mearth_tools
	filename = 'trigger_warmup' + rw(2000+ (year mod 2000)) + '_' + rw(nstars)+'stars'
	filename += '_'+ string(format='(F3.1)', duration_min*24) + 'hours'
	if maxrednoise lt 100 then	filename += '_'+'rednoisebelow' + string(format='(F3.1)', maxrednoise) 
	filename +='.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=10, ysize=7.5, /inches, /color
	endif
	cleanplot
	radii_to_plot = [4,3,2]
		b_max = 1
			!p.charsize=0.6
;			xr = [0, max(cloud.injected.n_nights)]
			xr=[0,120]
			erase
			smultiplot, /init, [2,2+n_elements(radii_to_plot)], ygap=0.005, xgap=0.005, /rowm

			for i=0, n_elements(radii_to_plot)-1 do begin
				i_plot = where(cloud.recovered.depth_uncertainty lt 1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min and cloud.injected.radius eq radii_to_plot[i])
				smultiplot
				if i eq 0 then title='simulations of ' + rw(nstars) + ' random stars from the ' + rw(2000+ (year mod 2000)) + '-' + rw(2000+ (year mod 2000) +1) + ' season' else title=''
				plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].n_untriggered_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3, ytitle= goodtex('D/\sigma') + ' for !C' + string(form='(F3.1)', radii_to_plot[i]) + goodtex('R_{Earth}'), errcolor=220, title=title
				plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_untriggered_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3, /over
				if i eq 2 then al_legend, /top, /left, box=0, 'up to start of trigger', charsize=1.1, charthick=2
			endfor

			smultiplot
			i_plot = where(cloud.recovered.depth_uncertainty lt 1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min)
			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].n_untriggered_sigma/cloud.injected[i_plot].n_untriggered_sigma, psym=3, yr=[-1,2], n_bins=max(xr), xs=3, xr=xr, ytitle='Recovered/Injected', errcolor=220
			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_untriggered_sigma/cloud.injected[i_plot].n_untriggered_sigma, psym=3, yr=[-1,2], n_bins=max(xr), xs=3, xr=xr, /over

 			smultiplot
			sigma = cloud.injected[i_plot].depth_uncertainty*cloud.injected[i_plot].n_sigma/cloud.injected[i_plot].n_untriggered_sigma
			plot_binned, /justbins, cloud.injected[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], ytitle=goodtex('Planet Detectable!Cat 3\sigma in Single Event'), xtitle='# of Nights Star was Observed before Event',errcolor=220

			sigma = cloud.recovered[i_plot].depth_uncertainty*cloud.recovered[i_plot].n_sigma/cloud.recovered[i_plot].n_untriggered_sigma
			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], /over



		loadct, 39


			for i=0, n_elements(radii_to_plot)-1 do begin
				i_plot = where(cloud.recovered.depth_uncertainty lt 1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min and cloud.injected.radius eq radii_to_plot[i])
				smultiplot
				if i eq 0 then begin
					if maxrednoise lt 100 then  title='(durations longer than '+string(format='(F3.1)', duration_min*24)+ ' hours; rednoise below '+ string(format='(F3.1)', maxrednoise) +')' else title='(durations longer than '+string(format='(F3.1)', duration_min*24)+ ' hours)'
				endif else title=''

				plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].n_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3,errcolor=220, title=title;, ytitle=goodtex('D/\sigma'), errcolor=150
				plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3, /over
				if i eq 2 then al_legend, /top, /left, box=0, 'up to end of trigger', charsize=1.1, charthick=2

			endfor

			smultiplot
			i_plot = where(cloud.recovered.depth_uncertainty lt 1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min)
			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_sigma/cloud.injected[i_plot].n_sigma, psym=3, yr=[-1,2], n_bins=max(xr), xs=3, xr=xr;, ytitle='Recovered/Injected'

			smultiplot
			sigma =cloud.injected[i_plot].depth_uncertainty
			plot_binned, /justbins, cloud.injected[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], xtitle='# of Nights Star was Observed before Event', errcolor=220
			sigma =cloud.recovered[i_plot].depth_uncertainty
			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], /over

; 			smultiplot
; 			plot_binned, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_sigma/cloud.recovered[i_plot].n_untriggered_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0,2], ytitle=goodtex('Trigger Bump')



			smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
;	if question(/int, 'hey?') then stop
END