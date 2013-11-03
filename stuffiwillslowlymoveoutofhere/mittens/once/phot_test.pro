c = load_ensemble(p)
@filter_parameters
nights = round(c.mjd_obs - mearth_timezone())
n_nights = n_elements(uniq(nights, sort(nights)))

set_plot, 'ps'
loadct, 39

device, filename='photometry_in_planet_radii.eps', /encap, /color, /inches, xsize=7, ysize=5
!p.charsize=1
nsigma = 2.5
plothist, sqrt(nsigma)*p.planet_1sigma, bin=0.5, xr=[0,max(sqrt(nsigma)*p.unfiltered_planet_1sigma)], thick=3, yr=[0,100], xtitle=goodtex(string(format='(F3.1)', nsigma)+'\sigma Photometric Precision Per Binned Point (Earth radii)')
plothist, sqrt(nsigma)*p.unfiltered_planet_1sigma, bin=0.5, /over, color=250, thick=3
plothist,sqrt(nsigma)* p.predicted_planet_1sigma, bin=0.5, /over, linestyle=2, thick=3
plothist, sqrt(nsigma)*p.planet_1sigma, bin=0.5, /over, thick=3
legend, box=0, color=[0,250,0], linestyle=[2,0,0], thick=[3,3,3], ['noise model', 'straight from pipeline', 'with CM + nightly offset!C!C(only '+strcompress(/remo, n_nights)+' nights so far...)'] , /top, /right
device, /close
epstopdf, 'photometry_in_planet_radii.eps'

device, filename='predicted_vs_actual_photometry.eps', /encap, /color, /inches, xsize=7, ysize=5
@psym_circle

plot, p.predicted_rms, p.unfiltered_rms, /nodata, xtitle='RMS predicted from Noise Model', ytitle='RMS measured from at most '+strcompress(/remo, n_nights)+' Nights of Data', symsize=0.5
oplot, [0,1], [0,1], linestyle=2
oplot, psym=8, p.predicted_rms, p.unfiltered_rms,  color=250, symsize=0.5
oplot, psym=8, p.predicted_rms, p.rms, symsize=0.5
legend, box=0, color=[250,0], psym=8, ['straight from pipeline', 'with CM + nightly offset!C!C(only '+strcompress(/remo, n_nights)+' nights so far...)'] , /top, /right
device, /close
epstopdf, 'predicted_vs_actual_photometry.eps'