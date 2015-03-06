PRO performance_plots, xrange=xrange, eps=eps, remake=remake

	; SQL query only seems to work in IDL7.0
	; (run after saying)
	; setenv IDL_DIR /opt/idl/idl_7.0
	; setenv IDL_DLM_PATH /data/mearth1/db/idl
	; setenv PGSERVICE mearth

; for 2008.5 to 2013
;performance_plots, /eps, xr=[julday(1,1,2008) + 240, julday(1,1,2013) + 180] - 2400000L


	query = "SELECT binned_weather.mjdatdusk, binned_weather.dusk, binned_weather.dawn, coalesce(binned_exposures.tel, 0) as tel, binned_weather.hrbadwx, binned_weather.hrgoodwx, binned_exposures.hrexpose FROM (SELECT floor(bins.binstart - 0.8) as mjdatdusk, count(nullif(weatherisgood,TRUE)) as hrbadwx, count(nullif(weatherisgood,FALSE)) as hrgoodwx, min(bins.binstart) as dusk, max(bins.binend) as dawn FROM (SELECT min(dark.mjd) AS binstart, max(dark.mjd) AS binend, bit_or(dark.flags) as flags, bit_or(dark.flags) = 0 as weatherisgood FROM (SELECT * FROM weather WHERE (flags&64)=0 AND mjd < 57000) dark GROUP BY floor((dark.mjd-0.8)/0.01)) bins GROUP BY mjdatdusk ORDER BY mjdatdusk) binned_weather LEFT OUTER JOIN (SELECT ebins.tel, floor(ebins.binstart - 0.8) as mjdatdusk, coalesce(count(nullif(ebins.nframes,0)), 0) as hrexpose FROM (SELECT min(mjd) as binstart, max(mjd) as binend, count(*) as nframes, tel FROM frame WHERE mjd < 57000 GROUP BY floor((mjd - 0.8)/0.01), tel) ebins GROUP BY mjdatdusk, ebins.tel) binned_exposures ON (binned_weather.mjdatdusk = binned_exposures.mjdatdusk) ORDER BY binned_weather.mjdatdusk"

	if keyword_set(remake) or file_test('sql_search_results.idl') eq 0 then begin
		sql = pgsql_query(query, /verb) 
		save, sql, filename='sql_search_results.idl'
	endif else restore, 'sql_search_results.idl'

	i_weird = where(sql.hrexpose gt 100, n_weird)
	if n_weird gt 0 then sql[i_weird].hrexpose = 0

	
; 	nudge = sql
; 	nudge.mjdatdusk += 0.510
; 	nudge.hrexpose =0
; 	nudge.hrbadwx =0
; 	d = [sql, nudge]
	twilight = 0.04
	d = sql
	d = d[sort(d.mjdatdusk)]
	if keyword_set(xrange) then !x.range = xrange else !x.range = range(d.mjdatdusk)


	if keyword_set(eps) then begin
		set_plot, 'ps'
		filename='performance_plot.eps'
		device, /encapsulate, /color, filename=filename, xsize=10, ysize=6, /inches
	endif
;	device, decomposed=0
        smultiplot, /init, [1,8], ygap=0.02
	bottom = ((d.dusk - 0.8) mod 1) + twilight	
	i = where(bottom gt 0.4, complement=j)
	bottom[i] = interpol(bottom[j], d[j].mjdatdusk, d[i].mjdatdusk)
	top = ((d.dawn - 0.8) mod 1)  - twilight
	i = where(top lt 0.6, complement=j)
	top[i] = interpol(top[j], d[j].mjdatdusk, d[i].mjdatdusk)

	x = d.mjdatdusk 
	observing = d.hrexpose*0.01
	badweather = d.hrbadwx*0.01*((top - bottom) - 2*twilight)/((top - bottom))

	n_years = 5
	years = indgen(n_years)+2009
	dates_to_print = julday(ones(n_years), ones(n_years),years) - 2400000.5d

	loadct, 0, /sil
        for tel=1,8 do begin
            i = where(d.tel eq tel, n_tel)
            if n_tel gt 0 then begin
        	smultiplot
                plot, x, top, min_value=0.7, yr=range([top,bottom]), xs=7, ys=7, /nodata
		if tel eq 1 then begin
			loadct, file='~/zkb_colors.tbl', 0;54, /sil
			xyouts, dates_to_print, fltarr(n_years) + max(top) + 0.1,  string(years, format='(I4)'), alignment=0.5, charthick=3
		endif

; 		if tel eq 8 then begin
; 			axis, xaxis=0, xtickunits='Time'
; 		endif
;		oplot, x, bottom, max_value=0.3
		loadct, file='~/zkb_colors.tbl', 54, /sil
		polyfill, [reverse(x), x], [reverse(top), bottom], color=220, noclip=0


;			polyfill, [reverse(x), x], [reverse(top), top-badweather], color=200
;			polyfill, [reverse(x[i]), x[i]], [reverse(bottom[i]), bottom[i]+observing[i]]

		loadct, file='~/zkb_colors.tbl', 54, /sil
		for j=0, n_elements(badweather)-1 do begin
			polyfill, x[j] + [0,0,1.05,1.05,0], top[j] - [badweather[j], 0, 0, badweather[j], badweather[j]] > bottom[j], color=160, thick=1, noclip=0
		endfor
		loadct, file='~/zkb_colors.tbl', 0
		for j=0, n_tel-1 do begin
			polyfill, x[i[j]] + [0,0,1.05,1.05,0], bottom[i[j]]+ [observing[i[j]], 0, 0, observing[i[j]], observing[i[j]]] < top[i[j]], color=0, thick=1, noclip=0
		endfor
		loadct, file='~/zkb_colors.tbl', 0;54, /sil
		xyouts, min(xrange), mean(top*0.4 + bottom*0.6), alignment=1.0, 'tel'+ string(format='(I02)', tel) + '  ', charthick=3, color=0

            endif
        endfor
	smultiplot, /def
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif
END

