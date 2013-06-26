PRO load_stellar_properties

	common mearth_tools

	; get basic parameters from nc_adopt_best
	query = "select n.lspmn as lspmn, lspmn2name(n.lspmn) AS bestname, n.catra*180.0/3.1415926535 as ra, n.catdec*180.0/3.1415926535 as dec,  base10_to_60(n.catra, 'rad', ':', '', 2, 'hr') AS ra_string, base10_to_60(n.catdec, 'rad', ':', '+', 1, 'deg') AS dec_string, n.pmra, n.pmdec, n.vest, n.vmag as v, n.rsdss AS r, n.jmag AS j, n.hmag AS h, n.kmag AS k, n.spectype, n.distmod, 10^(0.2*(n.distmod+5)) as distance, n.plx as lit_plx, n.e_plx as lit_e_plx, p.plx as jason_plx, p.e_plx as jason_e_plx , n.mass, n.radius, n.lbol as lum FROM nc_adopt_best n LEFT OUTER JOIN prelim_plx p ON n.lspmn = p.lspmn ORDER BY lspmn;"
	sql = pgsql_query(query, /verb) 

	; add a few columns to the IDL structure
	ensemble_lspm = replicate(create_struct(sql[0], 'teff', 0.0), n_elements(sql))
	copy_struct, sql, ensemble_lspm
	ensemble_lspm.teff = (ensemble_lspm.lum/ensemble_lspm.radius^2)^0.25*5780.0
	
	; save the IDL structure in a central spot
	save, ensemble_lspm, filename='population/ensemble_lspm_properties.idl'

	; run through all ls####/ direcories and replace lspm_info.idl with updated ones
	f = file_search('ls*/')
	for i=0, n_elements(f)-1 do begin
		lspmn = long(stregex(/ext, f[i], '[0-9]+'))
		if lspmn gt 0 then begin
		;	mprint, f[i], lspmn
			lspm_info = get_lspm_info(lspmn)
			if n_tags(lspm_info) gt 0 then begin
				mprint, doing_string, 'saving stellar parameters to ', f[i] + '/lspm_info.idl'
				save, lspm_info, filename=f[i] + '/lspm_info.idl'
			endif else mprint, skipping_string, "couldn't find stellar parameters for ", f[i]
		endif
	endfor
	return
	
; ;	a test to see how bolometric luminosity estimates are working 
; 	set_plot, 'ps'
; 	filename='plots/testing_database_lbols.eps'
; 	device, filename=filename, /encap, xsize=6, ysize=6, /inc
; 	
; 	!p.multi=0
; 	!p.charsize=1
; 	plot, lspm.mass, lspm.teff, psym=1, symsize=0.25,  ys=3, xtitle='Mass (solar masses)', ytitle=goodtex('Effective Temperature [(L_{bol}/R^2)^{1/4}]')
; 	;xyouts, lspm.mass, lspm.teff, rw(lspm.n), charsize=1, charthick=1
; 	
; 	i = where(lspm.teff lt 2000)
; 	print_struct, lspm[i], ['n','vest', 'v','k', 'spectype', 'distance','mass', 'radius', 'lum', 'teff']
; 	
; 	device, /close
; 	epstopdf, filename

	
END