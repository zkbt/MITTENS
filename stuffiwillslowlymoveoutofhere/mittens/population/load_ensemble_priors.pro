	
FUNCTION load_ensemble_priors, prior_cloud, year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n

	
	subset = subset_of_stars('box_pdf.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range, n=n) + 'box_pdf.idl'
	skip_list = [	'ls3229/ye10/te04/', 'ls3229/ye10/te07/', 'ls1186/ye10/te01/'];, $

	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	subset = subset[sort(ye)]
	ls = long(stregex(/ext, stregex(/ext, subset, 'ls[0-9]+'), '[0-9]+'))
	ye = long(stregex(/ext, stregex(/ext, subset, 'ye[0-9]+'), '[0-9]+'))
	te = long(stregex(/ext, stregex(/ext, subset, 'te[0-9]+'), '[0-9]+'))
	n = n_elements(subset)
	restore, subset[0]
	
	tags = ['COMMON_MODE', 'AIRMASS', 'SKY', 'ELLIPTICITY', 'UNCERTAINTY_RESCALING'] ; not worth storing, they're fixed. need to look at results of night-by-night fits'LEFT_XLC', 'LEFT_YLC', 'RIGHT_XLC', 'RIGHT_YLC'
	prior_template = create_struct('LSPM', 0, 'STAR', get_lspm_info(0), 'STAR_DIR', '')
	for i=0, n_elements(tags)-1 do prior_template = create_struct(prior_template, tags[i], create_struct('COEF', 0.0, 'UNCERTAINTY', 0.0))
	prior_cloud = replicate(prior_template, n)
	for i=0, n-1 do begin
		prior_cloud[i].lspm = ls[i]
		temp = get_lspm_info(fix(ls[i]))
		prior_cloud[i].star = temp
		prior_cloud[i].star_dir = stregex(subset[i], /ext, 'ls[0-9]+/ye[0-9]+/te[0-9]+/')
		restore, subset[i]
		print, subset[i]
		erase
		for j=3, n_tags(prior_cloud)-1 do begin
			k = where(strmatch(priors.name, tags[j-3]), n_match)
			if n_match eq 1 then begin
				prior_cloud[i].(j).coef = priors[k].coef
				prior_cloud[i].(j).uncertainty = priors[k].uncertainty
			endif
		endfor
	endfor
		smultiplot, /init, [1, n_elements(tags)], ygap=0.01
		for j=3, n_tags(prior_cloud)-1 do begin
			k = where(strmatch(priors.name, tags[j-3]), n_match)
			smultiplot
			m = where(prior_cloud.(j).coef ne 0 and prior_cloud.(j).uncertainty ne 0, n_nonzero)
			if n_nonzero gt 1 then ploterror, ytitle=tags[j-3], m, prior_cloud[m].(j).coef, prior_cloud[m].(j).uncertainty, psym=8, xs=3, yr=((1.48*mad(prior_cloud[m].(j).coef)*[-1,1]*7 + median(prior_cloud[m].(j).coef))> min(prior_cloud[m].(j).coef)) < max(prior_cloud[m].(j).coef), ys=3
		endfor
		smultiplot, /def
		cleanplot
		xplot, 3
		plothist, prior_cloud.common_mode.coef, bin=0.001
		oplot_gaussian, prior_cloud.common_mode.coef, bin=0.001, center=center, sigma=sigma, /rms, pdf_params=[0.0031, 0.002]
		if keyword_set(year) then print, year
		print, '   common mode coefficients roughly follow ', center, ' \pm ' , sigma

	return, prior_cloud
END

;       11
;    common mode coefficients roughly follow    0.00301826 \pm    0.00178824
; 
;       10
;    common mode coefficients roughly follow    0.00724141 \pm    0.00435500
; 
;        9
;    common mode coefficients roughly follow    0.00379172 \pm    0.00244113
; 
;        8
;    common mode coefficients roughly follow    0.00309362 \pm    0.00195941
; 
; 	everything
;    common mode coefficients roughly follow    0.00367181 \pm    0.00333097

