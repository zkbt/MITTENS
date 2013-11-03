PRO	marpleplot_warmup, year=year, nstars=nstars, eps=eps, maxrednoise=maxrednoise, remake=remake
;	if ~keyword_set(year) then year = 11
	if ~keyword_set(nstars) then nstars = 100
	if keyword_set(remake) then begin
	 	cloud= compile_fake_triggers(year=year, nstars=nstars, minnights=100) 
		save, cloud, filename='trigger_warmup_data.idl'

	endif else restore, 'trigger_warmup_data.idl'

	duration_min = 1.0/24.0
	if ~keyword_set(maxrednoise) then maxrednoise=1000;max(cloud.recovered.rednoise)
	common mearth_tools
	filename = 'marpleplot_warmup' 
;	if keyword_set(year) then filename += rw(2000+ (year mod 2000)) + '_' 
;	filename += rw(nstars)+'stars'
;	filename += '_'+ string(format='(F3.1)', duration_min*24) + 'hours'
;	if maxrednoise lt 100 then	filename += '_'+'rednoisebelow' + string(format='(F3.1)', maxrednoise) 
	filename +='.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=2, /inches, /color
	endif
	cleanplot
	!p.thick=2
	!y.ticklen = 0.01
	radii_to_plot = [4,3,2]
		b_max = 1;0.25
			!p.charsize=0.60
			
;			xr = [0, max(cloud.injected.n_nights)]
			xr=[0,100]
			
; 			for i=0, n_elements(radii_to_plot)-1 do begin
; 				i_plot = where(cloud.recovered.depth_uncertainty lt 1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min and cloud.injected.radius eq radii_to_plot[i])
; 				smultiplot
; 				if i eq 0 then title='simulations of ' + rw(nstars) + ' random stars from the ' + rw(2000+ (year mod 2000)) + '-' + rw(2000+ (year mod 2000) +1) + ' season' else title=''
; 				plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].n_untriggered_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3, ytitle= goodtex('D/\sigma') + ' for !C' + string(form='(F3.1)', radii_to_plot[i]) + goodtex('R_{Earth}'), errcolor=220, title=title
; 				plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].n_untriggered_sigma, psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[0, 20], ys=3, /over
; 				if i eq 2 then al_legend, /top, /left, box=0, 'up to start of trigger', charsize=1.1, charthick=2
; 			endfor

; 			smultiplot
; 			i_plot = where(cloud.recovered.depth_uncertainty lt 0.01 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min)
; 			y = (cloud.injected[i_plot].depth - cloud.injected[i_plot].depth)/cloud.injected[i_plot].depth
; 			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, y, psym=3, yr=[-1,1], n_bins=max(xr), xs=3, xr=xr, ytitle=goodtex('D/D_{Injected}'), errcolor=220
; 			y = (cloud.recovered[i_plot].depth/1.086 - cloud.injected[i_plot].depth)/cloud.injected[i_plot].depth
; 			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, y, psym=3, yr=[-1,1], n_bins=max(xr), xs=3, xr=xr, /over
				erase
		smultiplot, /init, [2,2], ygap=0.01, xgap=0.003, /rowm;+n_elements(radii_to_plot)

			i_plot = where(cloud.recovered.depth_uncertainty lt 0.1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min and cloud.recovered.n_points lt 5 and cloud.recovered.rescaling lt 1.24)

			loadct, 39

 			smultiplot
			sigma = cloud.injected[i_plot].depth_uncertainty
			plot_binned, /quartile, /justbins, cloud.injected[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], ytitle=goodtex('Planet Identifiable at!C3\sigma in One Event!C(Earth radii)'), errcolor=220, thick=2, title=goodtex('MEarth stars with Low Unexplained Scatter (r_{\sigma, w} < 1.24),')
			sigma = cloud.recovered[i_plot].depth_uncertainty
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], /over, thick=2


			loadct, 39


			smultiplot
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].depth_uncertainty/cloud.injected[i_plot].depth_uncertainty, psym=3, yr=[0.7,3.4], n_bins=max(xr), xs=3, xr=xr, ytitle=goodtex('\sigma_{MarPLE}/\sigma_{Injected}'), errcolor=220, thick=2,xtitle='# of Nights Star had been Observed before Eclipse', ys=1
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].depth_uncertainty/cloud.injected[i_plot].depth_uncertainty, psym=3, yr=[0.7,3.4], n_bins=max(xr), xs=3, xr=xr, /over, thick=2, ys=1
			al_legend, box=0, linestyle=0, color=[220, 0], ['Injected', 'Recovered'], /top, /right, charsize=0.6, charthick=2, thick=3




			i_plot = where(cloud.recovered.depth_uncertainty lt 0.1 and  cloud.recovered.depth_uncertainty gt 0 and cloud.injected.b lt b_max and cloud.injected.t23 gt duration_min and cloud.recovered.n_points lt 5 and cloud.recovered.rescaling gt 1.24)

			loadct, 39
 			smultiplot
			sigma = cloud.injected[i_plot].depth_uncertainty
			plot_binned, /quartile, /justbins, cloud.injected[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5],  errcolor=220,title=goodtex('MEarth stars with High Unexplained Scatter (r_{\sigma, w} > 1.24)'), thick=2
			sigma = cloud.recovered[i_plot].depth_uncertainty
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].radius*sqrt(3*sigma/cloud.injected[i_plot].depth), psym=3,  n_bins=max(xr), xs=3, xr=xr, yr=[1,5], /over, thick=2


			loadct, 39


			smultiplot
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.injected[i_plot].depth_uncertainty/cloud.injected[i_plot].depth_uncertainty, psym=3, yr=[0.7,3.4], n_bins=max(xr), xs=3, xr=xr,  errcolor=220, thick=2,xtitle='# of Nights Star had been Observed before Eclipse', ys=1
			plot_binned, /quartile, /justbins, cloud.recovered[i_plot].n_nights, cloud.recovered[i_plot].depth_uncertainty/cloud.injected[i_plot].depth_uncertainty, psym=3, yr=[0.7,3.4], n_bins=max(xr), xs=3, xr=xr, /over, thick=2, ys=1
			al_legend, box=0, linestyle=0, color=[220, 0], ['Injected', 'Recovered'], /top, /right, charsize=0.6, charthick=2, thick=3






			smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
	if question(/int, 'hey?') then stop
END