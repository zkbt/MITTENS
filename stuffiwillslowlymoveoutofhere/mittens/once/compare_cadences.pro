xplot, xsize=1700, ysize=500



set_plot, 'ps'
device, filename='cadence_test.eps', /encap, /color, xsize=15, ysize=4, /inc
smultiplot, /init, colw=[1, .4], [2,1], xgap=0.04
smultiplot
!y.range = [0.02, -0.02]*1.5
plot, t3.hjd, t3.flux,  psym=3, xs=3, ytitle='Flux (mag.)', xtitle='MJD';xr=[56021.08, 56021.3],
cadence = 0.01
s3  = weighted_mean_smooth(t3.hjd, t3.flux, t3.fluxerr, time=cadence)
i3 = t8
i3.flux = interpol(s3.y, s3.x, t8.hjd)
i3.fluxerr = interpol(s3.err, s3.x, t8.hjd)
oploterror, i3.hjd, i3.flux, i3.fluxerr, color=250, psym=-8, errcolor=250
oploterror, t8.hjd, t8.flux, t8.fluxerr, color=70, psym=-8, errcolor=70
smultiplot, /doy
i = where(t8.hjd gt 0);56021)
ploterror, i3[i].flux, t8[i].flux, i3[i].fluxerr, t8[i].fluxerr, xr=!y.range, psym=8, xtitle='tel03 (binned)', ytitle='tel08'
smultiplot, /def
device, /close
epstopdf, 'cadence_test.eps'
set_plot, 'x'


