PRO load_stellar_properties
;+
; NAME:
;	load_stellar_parameters
; PURPOSE:
;	reads in the ensemble of stellar parameters from Jonathan's database, and stores them in IDL form
; CALLING SEQUENCE:
;	load_stellar_parameters
; INPUTS:
;	none
; KEYWORD PARAMETERS:
;	none
; OUTPUTS:
;	creates a file called 'population/ensemble_properties.idl' that contains all the MEarth objects
;	also adds a "mo_info.idl" file to each individual MEarth Object directory
; RESTRICTIONS:
; EXAMPLE:
; MODIFICATION HISTORY:
; 	Written by ZKBT (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2014.
;-
	common mearth_tools

	; get basic parameters from nc_adopt_best
	; original, before Jonathan cleaned up in summer 2014: north_query = "select n.lspmn as lspmn, n.lspmname as pmname, n.hip, n.tycho, n.lhs, n.nltt, n.gliese, lspmn2name(n.lspmn) AS bestname, n.twomass as mo, n.catra*180.0/3.1415926535 as ra, n.catdec*180.0/3.1415926535 as dec,  base10_to_60(n.catra, 'rad', ':', '', 2, 'hr') AS ra_string, base10_to_60(n.catdec, 'rad', ':', '+', 1, 'deg') AS dec_string, n.pmra, n.pmdec, n.vest, n.vmag as v, n.rsdss AS r, n.jmag AS j, n.hmag AS h, n.kmag AS k, n.spectype, n.distmod, 10^(0.2*(n.distmod+5)) as distance, n.plx as lit_plx, n.e_plx as lit_e_plx, p.plx as jason_plx, p.e_plx as jason_e_plx , n.mass, n.radius, n.lbol as lum FROM nc_adopt_best n LEFT OUTER JOIN prelim_plx p ON n.lspmn = p.lspmn ORDER BY lspmn;"
	north_query = "select n.lspmn as lspmn, n.lspmname as pmname, n.hip, n.tycho, n.lhs, n.nltt, n.gliese, lspmn2name(n.lspmn) AS bestname, n.twomass as mo, n.catra*180.0/3.1415926535 as ra, n.catdec*180.0/3.1415926535 as dec,  base10_to_60(n.catra, 'rad', ':', '', 2, 'hr') AS ra_string, base10_to_60(n.catdec, 'rad', ':', '+', 1, 'deg') AS dec_string, n.pmra, n.pmdec, n.vest, n.vmag as v, n.rsdss AS r, n.jmag AS j, n.hmag AS h, n.kmag AS k, n.spectype, n.distmod, 10^(0.2*(n.distmod+5)) as distance, n.plx as plx, n.e_plx as e_plx, n.r_plx as r_plx, n.mass, n.radius, n.lbol as lum FROM nc_adopt_best n ORDER BY lspmn;"

	mprint, doing_string, 'querying the northern catalog out of the database'
	north_sql = pgsql_query(north_query, /verb) 

	if keyword_set(usesqlforsouth) then begin
		; these are kludged! would be best to have one homogenous catalog for all of MEarth!
		; get basic parameters from lspmsouth_33pc_midlatemdwarf
		south_query = "select n.twomass as mo,  n.pmname, n.hip, n.tycho, n.lhs, n.nltt, n.gliese, n.catra*180.0/3.1415926535 as ra, n.catdec*180.0/3.1415926535 as dec,  base10_to_60(n.catra, 'rad', ':', '', 2, 'hr') AS ra_string, base10_to_60(n.catdec, 'rad', ':', '+', 1, 'deg') AS dec_string, n.pmra, n.pmdec, n.vest, n.vbest as v, n.jmag AS j, n.hmag AS h, n.kmag AS k, n.pst as spectype, n.distmod, 10^(0.2*(n.distmod+5)) as distance, n.plx as lit_plx, n.e_plx as lit_e_plx, n.mass, n.radius FROM lspmsouth_33pc_midlatemdwarf n;"
		mprint, doing_string, 'querying the southern catalog out of the database'
		south_sql = pgsql_query(south_query, /verb) 
	
		; be very careful, the south is very much included as a kludge!
		south_inclusive = replicate(north_sql[0], n_elements(south_sql))
		clear_struct, south_inclusive
		copy_struct, south_sql, south_inclusive
	;	x = north_sql.radius
	;	plot, x, north_sql.lum, psym=3
	;	oplot, x, fit[0] + fit[1]*x + fit[2]*x^2 + fit[3]*x^3, psym=1
		fit = polyfit(north_sql.radius, north_sql.lum, 3)
		x = south_inclusive.radius
		south_inclusive.lum = fit[0] + fit[1]*x + fit[2]*x^2 + fit[3]*x^3
	endif else begin
		lum_fit = polyfit(north_sql.radius, north_sql.lum, 3)
		absk_fit = polyfit(north_sql.mass, north_sql.k - north_sql.distmod, 5)
		;plot, north_sql.mass, north_sql.k - north_sql.distmod, psym=1, xtitle='Mass', ytitle='absolute k'
		x = north_sql.mass
	;	oplot, north_sql.mass, absk_fit[0] + absk_fit[1]*x + absk_fit[2]*x^2 + absk_fit[3]*x^3 + absk_fit[4]*x^4+ absk_fit[5]*x^5, color=150, psym=3
		summaryfiles = '/home/jirwin/mearth/newsouth/'+['summary-lspmsouth.txt', 'summary-pmsu.txt', 'summary-recons.txt', 'summary-misc.txt']
		
			readcol, 'population/compiledsouthernstars.dat', twomassid, rah, ram, ras, decd, decm, decs, epoch, pm_ra, pm_dec, parallax, vmag, jmag, hmag, kmag, mass, radius, teff, mearthmag, mearthexptime, exposurespervisit, snrrequested, snrexpected, timepervisit, expectedplanetradius, numberofreferencestars, nameinoriginalcatalog, format='A,A,A,A,A,A,A,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,D,A1000', delimiter='|'
			this = replicate(north_sql[0], n_elements(twomassid))
			clear_struct, this
			this.mo = name2mo(twomassid)
			for j=0, n_elements(this)-1 do begin
				this[j].ra = ten(rah[j] + ':' + ram[j] + ':' + ras[j])*15.0
				this[j].dec = ten(decd[j] + ':' + decm[j] + ':' + decs[j])
			endfor
			this.ra_string = rah + ':' + ram + ':' + ras
			this.dec_string = decd + ':' + decm + ':' + decs
			this.pmra = pm_ra
			this.pmdec = pm_dec
			this.plx = parallax
			this.v = vmag
			this.vest = vmag
			this.j = jmag
			this.h = hmag
			this.k = kmag
			this.mass = mass
			this.radius = radius
			x = radius
			this.lum = lum_fit[0] + lum_fit[1]*x + lum_fit[2]*x^2 + lum_fit[3]*x^3

			x = this.mass
			absk = absk_fit[0] + absk_fit[1]*x + absk_fit[2]*x^2 + absk_fit[3]*x^3 + absk_fit[4]*x^4+ absk_fit[5]*x^5
			this.distmod = this.k - absk
			this.distance = 10^(0.2*(this.distmod+5))
			this.bestname = nameinoriginalcatalog
			if n_elements(south) eq 0 then south = this else south = [south, this]
      
	endelse
	combined = [north_sql, south]
	
	; add a few columns to the IDL structure
	mo_ensemble = replicate(create_struct(combined[0], 'teff', 0.0), n_elements(combined))
	copy_struct, combined, mo_ensemble
	mo_ensemble.teff = (mo_ensemble.lum/mo_ensemble.radius^2)^0.25*5780.0
	mo_ensemble.mo = strip_twomass(mo_ensemble.mo)
	bad = where(mo_ensemble.bestname eq '', nbad)
	if nbad > 0 then mo_ensemble[bad].bestname = mo_ensemble[bad].mo
	; save the IDL structure in a central spot
	
	save, mo_ensemble, filename='population/mo_ensemble.idl'

	; loop through all stars in north and south samples, creating a folder for each
	for i=0, n_elements(mo_ensemble)-1 do begin
		mo_info = mo_ensemble[i]
		this_mo_dir = mo_prefix + mo_ensemble[i].mo + '/'
		; for this MO, save an info structure into the uppermost MO directory
		if n_tags(mo_info) gt 0 then begin
			if n_tags(mo_info) gt 0 then begin
				mprint, doing_string, 'saving stellar parameters to ', this_mo_dir + 'mo_info.idl'
				if file_test(this_mo_dir) eq 0 then begin
					mprint, tab_string, doing_string, 'creating ' + this_mo_dir
					file_mkdir, this_mo_dir
				endif
				save, mo_info, filename=this_mo_dir + 'mo_info.idl'
				mprint, tab_string, doing_string, 'stellar parameters were saved to ' + this_mo_dir + 'mo_info.idl'
			endif else mprint, skipping_string, "couldn't find stellar parameters for ", this_mo_dir
		endif
		; hopefully, this should only be used once, to move files from old "lsNNNN" directories into newer "moNNNNNNN+NNNNN" directories based on 2MASS names
;		lspmn = mo_ensemble[i].lspmn
;		this_ls_dir = 'ls'+string(lspmn, form='(I04)') +'/'
;		if lspmn gt 0 then begin
;			if file_test(this_ls_dir) then begin
;				mprint, doing_string, 'moving all files from ', this_ls_dir, ' to ', this_mo_dir
;				file_move, this_ls_dir+'*', this_mo_dir, /verbose
;				file_delete, this_ls_dir
;			endif else mprint, tab_string, skipping_string, this_ls_dir + "doesn't exist!"
;		endif
	endfor
	
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