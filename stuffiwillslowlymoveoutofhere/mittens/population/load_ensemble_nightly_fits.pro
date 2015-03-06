	
FUNCTION load_ensemble_nightly_fits, cloud, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n

	
	subset = subset_of_stars('box_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n) + 'nightly_fits.idl'

	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	subset = subset[sort(ye)]
	ls = long(stregex(/ext, stregex(/ext, subset, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, subset, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(subset)
	restore, subset[0]
	
	tags = ['COMMON_MODE', 'AIRMASS', 'SEE', 'SKY', 'ELLIPTICITY', 'LEFT_XLC', 'LEFT_YLC', 'RIGHT_XLC', 'RIGHT_YLC', 'UNCERTAINTY_RESCALING']
	template = create_struct(tags[0], create_struct('COEF', 0.0, 'UNCERTAINTY', 0.0))
	for i=1, n_elements(tags)-1 do template = create_struct(template, tags[i], create_struct('COEF', 0.0, 'UNCERTAINTY', 0.0))
;	cloud = replicate(template, n)
	for i=0, n-1 do begin
		restore, subset[i]
		print, subset[i]
		erase
		this = replicate(template, n_elements(nightly_fits[0,*]))
		if n_elements(cloud) gt 0 then begin
		;	smultiplot, /init, [1, n_elements(tags)], ygap=0.01
			for j=0, n_elements(tags)-1 do begin
				k = where(strmatch(nightly_fits.name, tags[j]), n_match)
				if n_match gt 0 then begin
					this.(j).coef = nightly_fits[k].coef
					this.(j).uncertainty =nightly_fits[k].uncertainty
				endif
				i_nonzero = where(cloud.(j).coef ne 0, n_nonzero)
		;		if n_nonzero gt 0 then ploterror, ytitle=tags[j], i_nonzero, cloud[i_nonzero].(j).coef, cloud[i_nonzero].(j).uncertainty, psym=8, xs=3
				
			endfor
			if stddev(this.uncertainty_rescaling.coef) then begin
				!p.multi=[0,1,3]
				plothist, this.uncertainty_rescaling.coef, bin=0.1, xout, yout, xs=3, ys=3, xr=[0.5, max(this.uncertainty_rescaling.coef)>2]
			 	restore, strmid(subset[i], 0, strpos(subset[i], 'nightly_fits.idl')) + 'box_pdf.idl'
				k = where(strmatch(spliced_clipped_season_fit.name, 'UNCERTAINTY_RESCALING'), n_match)
				resc = spliced_clipped_season_fit[k].coef
				err = spliced_clipped_season_fit[k].uncertainty
				plots, resc + [-err, err], [max(yout), max(yout)]/2., thick=3
				plots, resc , max(yout)/2., psym=8, symsize=3
				
				plot, this.uncertainty_rescaling.coef, nothings.n, psym=1, ys=3, xs=3,  xr=[0.5, max(this.uncertainty_rescaling.coef)>2]

				q = where(nothings.n gt 3)

				if n_elements(q) gt 3 then begin
					resc = total(this[q].uncertainty_rescaling.coef/this[q].uncertainty_rescaling.uncertainty^2)/total(1/this[q].uncertainty_rescaling.uncertainty^2)
					err  = sqrt(1/total(1/this[q].uncertainty_rescaling.uncertainty^2))*sqrt(n_elements(this[q].uncertainty_rescaling.coef))
					print, resc, err, total((this[q].uncertainty_rescaling.coef - resc)^2/this[q].uncertainty_rescaling.uncertainty^2)/n_elements(this[q].uncertainty_rescaling.coef)
					plots, resc + [-err, err], [max(nothings.n), max(nothings.n)]/2., thick=3
					plots, resc , max(nothings.n)/2., psym=8, symsize=3
	
	
					ploterror,q, this[q].uncertainty_rescaling.coef, this[q].uncertainty_rescaling.uncertainty
					hline, resc + err*[-1,1], linestyle=1
					hline, resc
					if question(int=int, 'hmmmm?') then stop
				endif
			endif
		;	smultiplot, /def		
		endif
		if n_elements(cloud) eq 0 then cloud = this else cloud = [cloud, this]
	endfor
	return, cloud
END