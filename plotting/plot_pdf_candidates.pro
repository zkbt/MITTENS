PRO plot_pdf_candidates, c=c, xrange=xrange, yrange=yrange, diag=diag, show_all=show_all,  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, duration_min=duration_min, octopus=octopus, vartools=vartools,combined=combined
	common mearth_tools
	if not keyword_set(c) then c = load_pdf_candidates(year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n, octopus=octopus, vartools=vartools,combined=combined)
	if ~keyword_set(duration_min) then duration_min = 0
	if keyword_set(show_all) then i_ok = indgen(n_elements(c)) else	i_ok = where(c.ignore eq 0 and c.known eq 0 and c.variability eq 0 and c.duration ge duration_min/24. and c.period gt 0.1)
	cleanplot, /silent
set_star, /random, n=50
	screensize = get_screen_size()
	xsize = screensize[0]*0.85
	ysize = xsize*0.25
	charsize = xsize/1000.0

	 				!p.charsize=charsize

					xplot = c.period
					yplot =  c.depth/c.depth_uncertainty
	c = c
	i = 0
	first = 1
	x =0
	y = 0
	!mouse.button=2
	title=''
	gray=220
	while(!mouse.button lt 4 ) do begin
		cleanplot
		xplot, xsize=xsize, ysize=ysize, /top, xpos=0

	if keyword_set(show_all) then i_ok = indgen(n_elements(c)) else	i_ok = where(c.ignore eq 0 and c.known eq 0 and c.variability eq 0 and c.duration ge duration_min/24. and c.period gt 0.1)

		!p.charsize=charsize
		erase

		!p.position = [0.075, 0.15, .28, .9]
		loadct, 0, /silent
		case i of
			0: 	begin
					xplot = c.period
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Candidate Period (days)'
					ytitle = goodtex('D/\sigma')
				end
			1: 	begin
					xplot = c.stats.boxes[0]
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Boxes in LC (#)'
					ytitle = goodtex('D/\sigma')
				end
			2: 	begin
					xplot = c.stats.points
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Data Points in LC (#)'
					ytitle = goodtex('D/\sigma')
				end
			3: 	begin
					xplot = c.stats.periods_searched
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Number of Periods Searched'
					ytitle = goodtex('D/\sigma')
				end
			4: 	begin
					xplot = c.depth
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Candidate Depth (mag.)'
					ytitle = goodtex('D/\sigma')
				end
			5: 	begin
					xplot = c.n_points
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Data Points going into Candidate'
					ytitle = goodtex('D/\sigma')
				end
			6: 	begin
					xplot = c.n_boxes
					yplot =  c.depth/c.depth_uncertainty
					xtitle = 'Boxes going into Candidate'
					ytitle = goodtex('D/\sigma')
				end
		endcase
		if n_elements(yrange) eq 1 then yrange=[yrange, max(yplot[i_ok])]
	;	if not keyword_set(xrange) then 
		xrange = range(xplot[i_ok])
		if not keyword_set(yrange) then yrange = range(yplot[i_ok])
		plot, xplot, yplot, psym=1, /xlog, xs=3,  ys=3, /nodata, title='', xtitle=xtitle, ytitle=ytitle, xrange=xrange, yrange=yrange
		plots, xplot, yplot, psym=1, noclip=0, color=gray*(c.ignore or c.known or c.variability or c.duration lt duration_min/24.)
		plots, xplot[i_ok], yplot[i_ok], psym=1
;			1: xyouts, xplot, yplot, strcompress(/remo, c.star_dir), align=0.5, noclip=0, charsize=charsize, color=gray*(c.ignore or c.known or c.variability)
;			2: xyouts, xplot, yplot, strcompress(/remo, c.n_boxes) + ' boxes!C'+ strcompress(/remo, c.n_points) + ' points', align=0.5, noclip=0, charsize=charsize, color=gray*(c.ignore or c.known or c.variability)
;			3: xyouts, xplot, yplot, strcompress(/remo, 'D='+goodtex(string(format='(F5.3)', c.depth) + '\pm'+string(format='(F5.3)', c.depth_uncertainty))), align=0.5, noclip=0, charsize=charsize, color=gray*(c.ignore or c.known or c.variability)
		
		;print_struct, !mouse
		;print, x, y
		if not keyword_set(first) then begin

			printl
			print_struct, c[i_selected]
;			print_struct, c[i_selected]
			restore, c[i_selected].star_dir + 'box_pdf.idl'
		;	!p.position = [0.55, 0, .95, .9]
			!x.margin = [60,12]
			!y.margin=[16, 2]
			plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=c[i_selected]
			!x.margin = [60,12]
			!y.margin=[4, 17]

			plot_pdf_spectrum, octopus=octopus, dir=c[i_selected].star_dir, candidate=c[i_selected]
	

	;		legend, /top, /right, box=0, c[i_selected].star_dir
			xyouts, 0.98, 0.5, align=0.5, orient=90, 'EXPLORE?', charsize=4,charthick=4, /normal
			title =  c[i_selected].star_dir

 		endif
 				!p.charsize=charsize

		!p.position = [0.075, 0.15, .28, .9]
		plot, xplot, yplot, psym=1, /xlog, xs=3, ys=3, /nodata, title=title, xtitle=xtitle, ytitle=ytitle, xrange=xrange, yrange=yrange, /noerase
		if n_elements(i_selected) gt 0 then begin
				theta = findgen(21)/20*2*!pi
				usersym, cos(theta), sin(theta)
				plots, psym=8, symsize=6, xplot[i_selected], yplot[i_selected], color=250
		endif
		cursor, x, y, /down, /data
		if !mouse.button eq 1 then begin
			if !mouse.x gt !d.x_size*0.85 then begin
				common this_star
				star_dir = c[i_selected].star_dir
				mo_info = get_mo_info(c[i_selected].lspm)
				explore_pdf, diag=diag, 0.01, octopus=octopus,vartools=vartools, /hide
				inspect
				return
				!mouse.button = 0
				xplot, xsize=750, ysize=350, /top, xpos=0
			endif
			if x lt max(xrange) then begin
				print, x, y
				r = sqrt((yplot-y)^2/(yrange[1] - yrange[0])^2 + (alog10(xplot)-alog10(x))^2/(alog10(xrange[1]) - alog10(xrange[0]))^2)
				i_selected = where(r eq min(r))
				first =0
			endif
		endif
		if !mouse.button eq 2 then i = (i+1) mod 7

	endwhile
	clear
END