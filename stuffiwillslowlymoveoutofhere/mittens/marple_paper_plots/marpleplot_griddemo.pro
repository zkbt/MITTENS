PRO marpleplot_griddemo, eps=eps, first_night, name=name, random=random, blank=blank, stretch=stretch, png=png, yrange=yrange, nolegend=nolegend

	common mearth_tools
	common this_star
	filename =star_dir() + 'marpleplot_griddemo_'+string(format='(I05)', first_night)+'.eps'
	if ~keyword_set(stretch) then stretch=1
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=3.5*stretch, ysize=5, /inches, /color
	endif else begin
		!p.charsize=0.4
		
	endelse
	!x.title=''
	restore, star_dir() + 'box_pdf.idl'
	restore, star_dir() + 'inflated_lc.idl'
	restore, star_dir() + 'variability_lc.idl'
	restore, star_dir() + 'cleaned_lc.idl'
if file_test(star_dir + 'nightly_fits.idl') then 	restore, star_dir+'nightly_fits.idl'
                
; restore, star_dir() + 'jmi_file_prefix.idl'
; fits_lc = mrdfits(jmi_file_prefix + '_lc.fits',1,h)
; i_target = where(fits_lc.lspm eq  lspm_info.n)

                                  
	nnights=1
	nights = round(inflated_lc.hjd - mearth_timezone())
	uniq_nights = nights[uniq(nights, sort(inflated_lc.hjd))]
	if keyword_set(random) then first_night = uniq_nights[randomu(seed)*n_elements(uniq_nights)]
	
	h = histogram(bin=nnights, uniq_nights, reverse_indices=ri)
	i_contig = where(h eq nnights, n_contig)
	if n_contig gt 0 then begin
		i = i_contig[0]
		!y.margin[0] = 2
		smultiplot, [nnights+1,1+n_elements(boxes[0].depth) +2], /rowmaj, /init, xgap=0.003, ygap=0.003, colw=[ones(nnights), 0.35], rowh=[ones(1+n_elements(boxes[0].depth)),0.8, 0.001+2*file_test(star_dir + 'nightly_fits.idl')]

		for j=0, nnights-1 do begin
			if keyword_set(first_night) then night = first_night + j else night = uniq_nights[ri[ri[i_contig[0]]]]+j
			i_tonight = where(nights eq night, n_tonight)
			if n_tonight eq 0 then continue
			i_tonight = where(nights eq night)
			caldat, 2400000l + night , m, d, y
			str = strcompress(/remo, y) + '-' + strcompress(/remo, m) + '-' + strcompress(/remo, d)


			if j eq 0 then begin
				xrange = range(inflated_lc[i_tonight].hjd - night -mearth_timezone())
				middle =mean(xrange)
				xrange[0] = (xrange[0] - max(boxes.duration)*.7 ) < (middle- 4/24.)
				xrange[1] = (xrange[1] + max(boxes.duration)*.7 ) > (middle+ 4/24.)
				xrange *= 24
				if ~keyword_set(yrange) then yrange = [0.015, -0.015];stddev(inflated_lc[i_tonight].flux)*[1,-1]*3
				!x.style=3
				!y.style=3
				!y.ticklen = 0.005
			endif
	;		if j eq 0 then ytickname = [' ', '-0.01', ' ', '0', ' ', '0.01', ' '] else ytickname=''
			smultiplot
			if j eq 0 then begin
			;	ytickformat='(F5.2)'
;				ytickv=[0.01, 0, -0.01]
;				yticks=2	
			endif else begin
				ytickformat=''
			endelse
			if j eq 0 then ytitle='Photometry!C[mag.]' else ytitle=''
			if ~keyword_set(name) then name = 'lspm' +rw(lspm_info.n)
			loadct, 0
	!x.thick=1
	!y.thick=1
			plot, 24*(cleaned_lc[i_tonight].hjd - night -mearth_timezone()), cleaned_lc[i_tonight].flux, psym=-8, xrange=xrange, yrange=yrange, /nodata, ytickformat=ytickformat, yticks=yticks, ytickv=ytickv, ytitle=ytitle, title=name + ' ('+string(form='(F4.2)', lspm_info.radius) + goodtex('R_{!9n!3}') +'); '+ str
	;		plot, 24*(inflated_lc[i_tonight].hjd - night -mearth_timezone()), inflated_lc[i_tonight].flux, psym=-8, xrange=xrange, yrange=yrange, /nodata, ytickformat=ytickformat, yticks=yticks, ytickv=ytickv, ytitle=ytitle, title=name + ' ('+string(form='(F4.2)', lspm_info.radius) + goodtex('R_{!9n!3}') +'); '+ str

			hjdsupersampled = generate_highres_sampling(inflated_lc, box=box)
			model_middle = interpol((cleaned_lc.flux - cleaned_lc.flux), cleaned_lc.hjd, hjdsupersampled)
			model_uncertainty = 0.0*interpol(uncertainty_overall_model, cleaned_lc.hjd, hjdsupersampled)
;			model_middle = interpol((inflated_lc.flux - cleaned_lc.flux), inflated_lc.hjd, hjdsupersampled)
;			model_uncertainty = interpol(uncertainty_overall_model, inflated_lc.hjd, hjdsupersampled)
			dt = hjdsupersampled[1:*] - hjdsupersampled[0:*]
			gap_definition = 3*median(dt)
			starts_of_gaps = [where(abs(dt) gt gap_definition), n_elements(hjdsupersampled) -1 ]
			if starts_of_gaps[0] eq -1 then starts_of_gaps = n_elements(hjdsupersampled)-1
			ends_of_gaps = [0, where(abs(dt) gt gap_definition)+1]
			loadct, 58, file='~/zkb_colors.tbl'
			i_superintransit = where_intransit(struct_conv({hjd:hjdsupersampled}), candidate, n_superintransit)
			if n_superintransit gt 0 then begin
	;			if keyword_set(box) then begin
	;				model_middle[i_superintransit] += box.depth
	;				model_uncertainty[i_superintransit] = box.depth_uncertainty
	;			endif else begin
					model_middle[i_superintransit] += candidate.depth
					model_uncertainty[i_superintransit] = sqrt(candidate.depth_uncertainty^2 + model_uncertainty[i_superintransit]^2)
	;			endelse
			endif
			for q=0, n_elements(starts_of_gaps)-1 do begin
				oneway = hjdsupersampled[ends_of_gaps[q]:starts_of_gaps[q]]
				top = model_middle[ends_of_gaps[q]:starts_of_gaps[q]] + model_uncertainty[ends_of_gaps[q]:starts_of_gaps[q]]
				bottom =model_middle[ends_of_gaps[q]:starts_of_gaps[q]] - model_uncertainty[ends_of_gaps[q]:starts_of_gaps[q]]
				xvert = [ oneway,  reverse(oneway)];hjdsupersampled[ends_of_gaps[q]],
				yvert = [top, reverse(bottom) ];model_middle[ends_of_gaps[q]] - model_uncertainty[ends_of_gaps[q]], 
				polyfill, 24*(xvert-night -mearth_timezone()), yvert, color=220, noclip=0
				oplot, 24*(oneway-night -mearth_timezone()), top, color=150, thick=3
				oplot, 24*(oneway-night -mearth_timezone()), bottom, color=150, thick=3
			endfor



	duration_bin = median(boxes[0].duration[1:*]  - boxes[0].duration)
	i_duration = value_locate(boxes[0].duration-duration_bin/2, candidate.duration)	
	i_interesting = where(boxes.n[i_duration] gt 0)
	i_intransit = i_interesting[where_intransit(boxes[i_interesting], candidate, i_oot=i_oot,  /box, n_intransit)];buffer=-candidate.duration/4,



			loadct, 0
			theta = findgen(17)/16*2*!pi
			usersym, cos(theta), sin(theta), /fill

		for i_seg=0, n_elements(segments_boundaries)-1 do begin
			if i_seg eq 0 then seg_start = 0 else seg_start = segments_boundaries[i_seg-1]
			segment = seg_start + indgen(segments_boundaries[i_seg] - seg_start)
			;plot_lc, xaxis=lcs.(i)[segment].x,xtickunits=xtickunits, lcs.(i)[segment], symsize=symsize*(1.0 - keyword_set(binned)*0.5), time=time, nobad=fake, colorbar=colorbars[i_seg], /noaxes
			loadct,file= '~/zkb_colors.tbl', colorbars[i_seg]
			oplot,24*( cleaned_lc[segment].hjd - night -mearth_timezone()), cleaned_lc[segment].flux, psym=8, symsize=0.25 + (~keyword_set(eps)*0.75)

		endfor
		loadct, 0

	;		oplot,24*( cleaned_lc[i_tonight].hjd - night -mearth_timezone()), cleaned_lc[i_tonight].flux, psym=8, symsize=0.25
;		oplot,24*( inflated_lc[i_tonight].hjd - night -mearth_timezone()), inflated_lc[i_tonight].flux, psym=8, symsize=0.25
					offset =  max(xrange) + (max(xrange) - min(xrange))*0.25
;;

			if ~keyword_set(nolegend) then if j eq nnights-1 then xyouts, align=0.5, offset, 0, 'transit!Cduration:', charsize=1, charthick=1.5
			usersym, cos(theta), sin(theta)

			for i=0, n_elements(boxes[0].depth)-1 do	begin
				smultiplot, dox=i eq n_elements(boxes[0].depth)-1
				color = round((i+1)*254.0/n_elements(boxes[0].depth)+0.01)
				loadct, 0
				if i eq 4 and j eq 0 then ytitle=goodtex('Hypothetical Transit Depths (D\pm\sigma_{MarPLE})!C[mag.]') else ytitle=''
				if i eq  n_elements(boxes[0].depth)-1 then xtitle= 'Time from Midnight (hours)' else xtitle=''
				plot, 24*(boxes.hjd - night -mearth_timezone()), boxes.depth[i], xrange=xrange, yrange=yrange,thick=1, psym=8, /nodata, ytickformat=ytickformat, yticks=yticks, ytickv=ytickv, ytitle=ytitle, xtitle=xtitle
				hline, linestyle=1, 0
				loadct, 39
;				oplot, boxes.hjd - night -mearth_timezone(), boxes.depth[i], color=color, thick=1, psym=3
				errplot, 24*(boxes.hjd - night -mearth_timezone()), boxes.depth[i] - boxes.depth_uncertainty[i], boxes.depth[i] + boxes.depth_uncertainty[i],   color=color,  thick=2
				if ~keyword_set(nolegend) then if j eq nnights-1 then begin
					up = 0.45*max(yrange)
					down = 0.8*max(yrange)
					left = -1.5/24
					right = 1.5/24
					ingress = -0.5*boxes[0].duration[i]
					egress = 0.5*boxes[0].duration[i]
					
					plots, color=color, thick=4, offset+ 24*[left, ingress, ingress, egress, egress, right], [up,up,down,down,up,up]
					xyouts, offset, 0, align=0.5, string(format='(F3.1)', boxes[0].duration[i]*24) + ' hrs'
				endif
				if i eq i_duration then begin
					i_closest = where(abs(24*(boxes[i_intransit].hjd- night -mearth_timezone()) ) eq min(abs(24*(boxes[i_intransit].hjd- night -mearth_timezone())) ))
					i_closest = i_closest[0]
				;	plots, 24*(boxes[i_intransit[i_closest]].hjd- night -mearth_timezone() + candidate.duration*[-0.5, -0.5, 0.5, 0.5, -0.5]),  candidate.depth+candidate.depth_uncertainty*[1, -1, -1, 1, 1]
					plots, 24*(boxes[i_intransit[i_closest]].hjd- night -mearth_timezone()),  candidate.depth, psym=7, thick=3
				endif
			endfor
			
			smultiplot
			smultiplot
			!p.position[0] = 0.2
			!p.position[2] = 0.85
			; KLUDGE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
if file_test(star_dir + 'nightly_fits.idl') then begin
; 			priors[where(name eq 'MERID_VERSION05')].coef -= priors[where(name eq 'VERSION05')].coef
; 			priors[where(priors.name eq 'MERID_VERSION05')].uncertainty = sqrt(priors[where(priors.name eq 'MERID_VERSION05')].uncertainty^2+ priors[where(priors.name eq 'VERSION05')].uncertainty^2)
; 
; 			nightly_fits[where(priors.name eq 'MERID_VERSION05'), *].coef -= nightly_fits[where(priors.name eq 'VERSION05'), *].coef
; 			nightly_fits[where(priors.name eq 'MERID_VERSION05'), *].uncertainty = sqrt(nightly_fits[where(priors.name eq 'MERID_VERSION05'), *].uncertainty^2+ nightly_fits[where(priors.name eq 'VERSION05'), *].uncertainty^2)
; 
; 			jmi_merid = fits_lc[i_target].sfit_dc[n_elements(fits_lc[i_target].sfit_dc)-1] - mean(fits_lc[i_target].sfit_dc)
; 
; 			priors[where(priors.name eq 'MERID_VERSION05')].coef -= jmi_merid 
; 			nightly_fits[where(priors.name eq 'MERID_VERSION05'), *].coef -= jmi_merid 
			
			parameters =[ 'NIGHT'+rw(night), 'COMMON_MODE','MERID_VERSION05','LEFT_XLC', 'LEFT_YLC','RIGHT_XLC',  'RIGHT_YLC']
			parameter_names =' ' +goodtex([ 'v_{night}', 's_{CM}',  's_{merid}', 's_{x,0}', 's_{y,0}', 's_{x,1}', 's_{y,1}'])
			n_par = n_elements(parameters)
			print_struct, priors
			for q=0, n_par-1 do begin
				i_par = where(priors.name eq parameters[q], n_match)
				if n_match eq 0 then continue
				if n_elements(i_parameters) eq 0 then i_parameters = i_par else i_parameters = [i_parameters, i_par]
			endfor
			xpos =  indgen(n_par)
			nudge = 0.15
			loadct, 0
			plot, [0],  xr=range([xpos-2*nudge, xpos+2*nudge]), yr=max(abs(priors[i_parameters].coef) + priors[i_parameters].uncertainty)*[1,-1], xs=7, ys=8, ytitle='Nuisance!CParameters!C[mag.]'
			oploterror, xpos-nudge, priors[i_parameters].coef, priors[i_parameters].uncertainty, psym=3, errcolor=150, errthick=2
			i_night = where(nothings.hjd eq night, n_night)
			if n_night eq 1 then oploterror, xpos, nightly_fits[i_parameters, i_night[0]].coef, nightly_fits[i_parameters, i_night[0]].uncertainty, psym=3, errthick=2
			hline, 0, linestyle=1, color=150
			xyouts, xpos-0.08, nightly_fits[i_parameters, i_night[0]].coef - nightly_fits[i_parameters, i_night[0]].uncertainty,parameter_names, charsize=0.9, orient=45
; 			!p.position[0] = 0.8
; 			!p.position[2] = !p.position[0]+0.5*1/n_par
; 			parameters =['UNCERTAINTY_RESCALING']
; 			parameter_names =goodtex([  'r_{\sigma, w}'])
; 			n_par = n_elements(parameters)
; 
; 			for q=0, n_par-1 do begin
; 				i_par = where(priors.name eq parameters[q], n_match)
; 				if n_match eq 0 then continue
; 				i_parameters = i_par; else i_parameters = [i_parameters, i_par]
; 			endfor
; 			xpos =  indgen(n_par)
; 			nudge = 0.1
; 			loadct, 0
; 			yr= range([priors[i_parameters].coef + priors[i_parameters].uncertainty, priors[i_parameters].coef - priors[i_parameters].uncertainty, nightly_fits[i_parameters, i_night[0]].coef+ nightly_fits[i_parameters, i_night[0]].uncertainty,  nightly_fits[i_parameters, i_night[0]].coef- nightly_fits[i_parameters, i_night[0]].uncertainty])
; 			plot, [0],  xr=range([xpos-2*nudge, (xpos>1)+2*nudge]),  xs=7, ys=8, yr=yr
; 			oploterror, xpos-nudge, priors[i_parameters].coef, priors[i_parameters].uncertainty, psym=3, errcolor=150, errthick=2
; 			i_night = where(nothings.hjd eq night, n_night)
; 			if n_night eq 1 then oploterror, xpos, nightly_fits[i_parameters, i_night[0]].coef, nightly_fits[i_parameters, i_night[0]].uncertainty, psym=3, errthick=2
; 			hline, 0, linestyle=1
; 			xyouts, xpos+nudge, priors[i_parameters].coef, parameter_names, charsize=0.4, orient=45

			usersym, [-1,1,0, 0, 1, -1], [2,2,2,-2,-2,-2]/2.0, thick=2

	al_legend, /left, psym=8, color=[150, 0], [" = prior", " = this night's fit"], charsize=0.8, position = [3.5, 0.0017]
	
endif

; 			smultiplot
; 			plot, [0], xs=4, ys=4
; ;			!p.position[0] = 0.4
; ;			!p.position[2] = 0.9
; 
				loadct, 39

		endfor
		
		smultiplot, /def
	endif
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		if keyword_set(png) then epstopng, filename, /hide, dpi=200 else epstopdf, filename
	endif

END

;ls2496/ye08/te06/ has nice gap
