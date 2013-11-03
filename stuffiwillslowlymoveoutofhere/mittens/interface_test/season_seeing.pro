PRO season_seeing, eps=eps, remake=remake
	if keyword_set(remake) or file_test('seeing_sql.idl') eq 0 then begin
		query = "SELECT mjd, seeing, ellipt, windspd FROM frame WHERE mjd > 54000"
		sql = pgsql_query(query, /verb)
		save, sql, filename='seeing_sql.idl'
	endif else restore, 'seeing_sql.idl'
cleanplot
if keyword_set(eps) then begin
	set_plot, 'ps'
	device, filename = 'season_seeing.eps', /encap, /color, xsize=20, ysize=4, /inches
endif else 	xplot, 2, xsize=2000, ysize=600

	!p.thick=2
	!x.thick =2
	!y.thick=2
	yrange=[0,10]
	maxwindspd=20
	maxellipt = 0.2
	ntoplot = 5e4
	hatl=10
; 	xplot, 1, xsize=2000, ysize=600
; 	plot_binned, sql.mjd, sql.seeing*0.76, psym=3, /quart    , binwidth=7, xs=1


	smultiplot, [3,2], /init, colw=[1,1,2], ygap=0.0, xgap=0.01, rowh=[0.2, 1], /rowm
	
	
	i = where(sql.seeing gt 0.1 and sql.ellipt gt 0 and sql.windspd lt 55 and sql.windspd gt 0 and sql.mjd gt 55050, n)
	
	smultiplot, doy=0
	plothist, sql[i].windspd +randomu(seed,n), bin=1, xs=7, ys=7
	smultiplot, /doy
	plot_binned, sql[i].windspd +randomu(seed,n), sql[i].seeing*0.76, psym=3, /quart, ytitle='FWHM of MEarth Images (arcsec)', xtitle='Wind Speed (km/h)', yrange=yrange, xs=3, subset=10000
	vline, maxwindspd, thick=3, linestyle=2
	al_legend, box=0, /bottom, /right, 'error bars = 25 + 75% quartiles!C10000 of ' + rw(n_elements(sql[i])) + ' points plotted', charsize=0.7, charthick=2

	smultiplot
	plothist, sql[i].ellipt, bin=0.01,  xs=7, ys=7
	smultiplot, /doy
	plot_binned, sql[i].ellipt, sql[i].seeing*0.76, psym=3, /quart  , xtitle='Image Ellipticity', yrange=yrange, xs=3, subset=10000
	vline, maxellipt, thick=3, linestyle=2
	al_legend, box=0, /bottom, /right, 'error bars = 25 + 75% quartiles!C10000 of ' + rw(n_elements(sql[i])) + ' points plotted', charsize=0.7, charthick=2

	
	juldate, [2000,1,1,0,0,0], janfirst
	timeofyear = (0.5d + sql.mjd - janfirst) mod 365
	i = where(sql.seeing gt 0.1 and sql.ellipt lt maxellipt and sql.windspd lt maxwindspd and sql.ellipt gt 0 and sql.mjd gt 55050, n_good)
smultiplot
	plothist, timeofyear[i] + janfirst+2400000.d, bin=7,  xs=7, ys=7

smultiplot, /dox, /doy

	plot_binned, timeofyear[i] + janfirst+2400000.d, sql[i].seeing*0.76, psym=3, /quart   , binwidth=7, xtickunits='Month', yrange=yrange, xs=3, subset=10000
	xyouts, mean(range(timeofyear[i] + janfirst+2400000.d)), max(yrange), '!C!Cweekly averages between fall 2009 and early 2013!Cexluding the '+rw(string(float(n - n_good)/n*100, form='(I)')) +'% of observations with!Cwinds > '+string(maxwindspd, form='(I2)')+' km/h or ellipticity > ' + string(maxellipt, form='(F4.2)') +'!C!C', align=0.5, charthick=2

	al_legend, box=0, /bottom, /right, 'error bars = 25 + 75% quartiles!C10000 of ' + rw(n_elements(sql[i])) + ' points plotted', charsize=0.7, charthick=2
smultiplot, /def

if keyword_set(eps) then begin
	device, /close
	epstopdf, 'season_seeing.eps'
	set_plot, 'x'
endif
END

