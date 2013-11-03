PRO plot_residuals, top=top, eps=eps, png=png
common mearth_tools
common this_star
cleanplot, /silent
restore, star_dir + 'inflated_lc.idl'
restore, star_dir + 'variability_lc.idl'
restore, star_dir + 'ext_var.idl'
restore, star_dir + 'cleaned_lc.idl'
;s = replicate(create_struct(cleaned_lc[0], ext_var[0]), n_elements(cleaned_lc))
s = replicate({uncorrected_flux:0.0, variability_flux:0.0, cleaned_flux:0.0,  left_xlc:0.0, right_xlc:0.0, left_ylc:0.0, right_ylc:0.0, airmass:0.0, peak:0.0, off:0.0, rms:0.0, extc:0.0, see:0.0, ellipticity:0.0, sky:0.0, humidity:0.0, skytemp:0.0, common_mode:0.0}, n_elements(cleaned_lc));hjd:0.0d,
copy_struct, ext_var, s
;s.hjd = cleaned_lc.hjd
s.uncorrected_flux = inflated_lc.flux
s.variability_flux = variability_lc.flux
s.cleaned_flux = cleaned_lc.flux
tags = tag_names(s)
skip = 3
loadct, 0
cols=n_elements(tags)-skip
		screensize = get_screen_size()
; 		ysize=400
; 		ypos = screensize[1]-ysize
; 	xpos = 100
;xplot,  !d.window < 30 > 0, title=star_dir + ' + correlations'
!P.charsize=1.1
smultiplot, [cols,skip], /init, xgap=0.0, ygap = 0.01;, colwid=[ones((cols)-1)]
i_bulk = where(abs(s.uncorrected_flux) lt 5*1.48*mad(s.uncorrected_flux))
yrange = reverse(range(s[i_bulk].uncorrected_flux))
ytitle='Uncorrected'
for i=skip, n_tags(s)-1 do begin
	smultiplot
	loadct, 0

	plot_binned, s[i_bulk].(i), s[i_bulk].uncorrected_flux, psym=1, n_bins=10+(i eq skip)*20, ytitle=ytitle, yrange=yrange, xs=3
	offplot, s.(i), s.uncorrected_flux, color=150
	ytitle=''
endfor
ytitle='Variability'
for i=skip, n_tags(s)-1 do begin
	smultiplot
	loadct, 0

	plot_binned, s[i_bulk].(i), s[i_bulk].variability_flux, psym=1, n_bins=10+(i eq skip)*20,  ytitle=ytitle,  yrange=yrange, xs=3
	offplot, s.(i), s.variability_flux, color=150
	ytitle=''
endfor

ytitle='Cleaned'
for i=skip, n_tags(s)-1 do begin
	smultiplot, /dox
	loadct, 0

	plot_binned, s[i_bulk].(i), s[i_bulk].cleaned_flux, psym=1, n_bins=10+(i eq skip)*20,  ytitle=ytitle, xtitle=str_replace(tags[i], '_', '!C'), yrange=yrange, xs=3
	offplot, s.(i), s.cleaned_flux
	ytitle=''
endfor

smultiplot, /def
; 
; xplot, xsize=1000, ysize=1000,  !d.window +1 < 30 > 0, title=star_dir + ' | residuals', xpos=xpos, ypos=ypos
; loadct, 39
; plot_nd, s[i_bulk], dye = abs(s[i_bulk].cleaned_flux/cleaned_lc[i_bulk].fluxerr), psym=1, tags=4+indgen(4)
; xplot, xsize=1000, ysize=1000,  !d.window +1 < 30 > 0, title=star_dir + ' | residuals', xpos=xpos, ypos=ypos
; plot_nd, s[i_bulk], dye = abs(s[i_bulk].cleaned_flux/cleaned_lc[i_bulk].fluxerr), psym=1, tags=8+indgen(11)

END