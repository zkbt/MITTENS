PRO statpaper_compare_samples, jas=jas
cleanplot
readcol, '~/kepler_targets_francois.txt', fkic, b, c, fradius, e, f, g, h, i, j
readcol, '~/kepler_mdwarfs_dressing.txt', a, ctemp, c, d, cradius, f, g, h, i, j, k, l, m, n, o
;restore, '~/mearth_radii.idl'
restore, '~/mearth_stars.idl'
stars = stars[where(stars.phased.radius lt 0.35)]


if keyword_set(jas) then begin
	readcol, 'MEarth_Mass_Radius.txt', lspm_string, mass_old, radius_old, pi_literature, err_pi_literature, pi_photo, pi, err_pi, mass_new, radius_new, n_obs, format='A,D,D,D,D,D,D,D,D,D,D,L'
	lspm = fix(stregex(lspm_string, '[0-9]+', /ext))
	distance_originally_adopted = 1.0/pi_photo
	i_hasliterature = where(finite(pi_literature) and err_pi_literature/pi_literature lt 0.1, n_haslitpi)
	if n_haslitpi gt 0 then distance_originally_adopted[i_hasliterature] = 1.0/pi_literature[i_hasliterature]
	
	jason = struct_conv({lspm:lspm, mass_old:mass_old, radius_old:radius_old, distance:1.0/pi, err_distance:err_pi/pi^2, pi:pi, err_pi:err_pi, mass_new:mass_new, radius_new:radius_new, n_obs:n_obs, pi_literature:pi_literature, err_pi_literature:err_pi_literature, pi_photo:pi_photo, distance_originally_adopted:distance_originally_adopted, flat_rescaling:fltarr(n_elements(pi)),err_flat_rescaling:fltarr(n_elements(pi)),sin_rescaling:fltarr(n_elements(pi)),err_sin_rescaling:fltarr(n_elements(pi))})

	; KLUDGE! 9/17/2012!
	for i=0, n_elements(jason) -1 do begin
		i_match = where(stars.phased.lspm eq jason[i].lspm, n_match)
		if n_match eq 0 then continue
		if finite(jason[i].radius_new) and jason[i].radius_new lt 1 then begin
		
			stars[i_match].phased.mass = jason[i].mass_new
			stars[i_match].phased.radius = jason[i].radius_new
		endif
	endfor
	
endif

	mearth_radii = stars.phased.radius
	lspm = stars.obs.lspm
	s = sort(lspm)
	mearth_radii = mearth_radii[s]
	lspm = lspm[s]
	u = uniq(lspm)
	mearth_radii = mearth_radii[u]
	
set_plot, 'ps'
device, filename='statpaper_samples.eps', xsize=3.75, ysize=2, /inches, /color, /encapsulated
bin=0.02
!p.charthick=2
!p.charsize=1.0
!x.thick = 2
!y.thick = 2
!x.ticklen = 0.05
!y.ticklen= 0.02
!x.margin=[7,2]
!y.margin = [4,1]
plothist, cradius, xrange=[0.0, 1], yr=[0,690], bin=bin, thick=3, /nodata, ys=1, xtitle='Stellar Radius (solar radii)', ytitle='# of stars'
loadct, 39
;plothist,  /over, fradius,  bin=bin, thick=4, noclip=0, minvalue=1
plothist, /over, cradius, color=90, bin=bin, thick=4, noclip=0, minvalue=1
;i = where(mearth_radii lt 0.4)
plothist, /over, mearth_radii, color=254, thick=8, bin=bin, noclip=0, minvalue=1

;al_legend, box=0, color=[0, 220, 254], thick=[4, 4, 8], linestyle=0, ["Kepler Input Catalog", "Kepler's early M dwarfs", "MEarth targets"], charsize=.5
al_legend, box=0, color=[90, 254], thick=[ 4, 8], linestyle=0, ["Kepler's early M dwarfs", "MEarth targets"], charsize=.7

device, /close
epstopdf, 'statpaper_samples.eps'
stop
END