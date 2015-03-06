PRO print_star, remake=remake, quick=quick
;+
; NAME:
;	PRINT_STAR
; PURPOSE:
;	save summary of stellar info as a text file in a MITTENS directory
; CALLING SEQUENCE:
;	print_star, remake=remake
; INPUTS:
;	(knows about star directory through "this_star" common block)
; KEYWORD PARAMETERS:
; OUTPUTS:
; RESTRICTIONS:
; EXAMPLE:
; 	print_star
; MODIFICATION HISTORY:
; 	Written by ZKB (zberta@cfa.harvard.edu) as part of
;		MEarth 
;		IDL 
;		Tools for 
;		Transits of 
;		Extrasolar 
;		Neptunes and 
;		Super-earths
;	sometime between 2008 and 2011.
;-

        common this_star
        common mearth_tools
	if file_test(mo_dir() +'mo_info.idl') eq 0 or keyword_set(remake) eq 1 then begin
	;	if file_test(mo_dir()) eq 0 then file_mkdir, mo_dir()
		restore, mo_dir() + 'mo_info.idl'
		mprint, doing_string, 'printing star information to files'
		
		rah = long(mo_info.ra/15)
		ram = long((mo_info.ra/15 - rah)*60)
		ras = ((mo_info.ra/15 - rah)*60 - ram)*60
		decd = long(mo_info.dec)
		decm = long((mo_info.dec - decd)*60)
		decs = ((mo_info.dec - decd)*60-decm)*60
		pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)');+ "  (J2000)"
	
		openw, f, /get_lun, mo_dir() + 'demo.txt'
		printf, f, '<b>'+mo_dir()+'</b>'
		printf, f, pos_string
		close, f
		free_lun, f
	
		openw, f, /get_lun, mo_dir()+'pos.txt'
		printf, f, pos_string
		free_lun, f
	
		;link = 'http://simbad.u-strasbg.fr/simbad/sim-id?Ident='+mo_info.bestname+ '&NbIdent=1&Radius=2&Radius.unit=arcmin&submit=submit+id'
		openw, f, /get_lun, mo_dir() + 'mo_obs.txt'
;		printf, f, '<a href="' + link + '" style="color: black; font-weight:bold">' + mo_info.bestname + '</a>'
		printf, f, string(form='(A12)', 'star = '), mo_info.bestname
		printf, f, string(form='(A12)','lit_px = '), string(format='(F5.3)', mo_info.lit_plx), ' +/- ', string(format='(F5.3)', mo_info.lit_e_plx)
		printf, f, string(form='(A12)','jas_px = '), string(format='(F5.3)', mo_info.jason_plx), ' +/- ', string(format='(F5.3)', mo_info.jason_e_plx)
		printf, f, string(form='(A12)','pm = '), strcompress(string(format='(F5.2)', mo_info.pmra)), ' ', string(format='(F5.2)', mo_info.pmdec)
		printf, f, string(form='(A12)','distance = '), string(format='(F5.1)', mo_info.distance)

		printf, f, string(form='(A12)','V = '), string(format='(F4.1)', mo_info.v)
		printf, f, string(form='(A12)','J = '), string(format='(F4.1)', mo_info.j)
		printf, f, string(form='(A12)','H = '), string(format='(F4.1)', mo_info.h)
		printf, f, string(form='(A12)','K = '), string(format='(F4.1)', mo_info.k)
		close, f
		free_lun, f
	
		openw, f, /get_lun, mo_dir() + 'mo_phys.txt'
		printf, f, string(form='(A12)','mass = '), string(format='(F4.2)', mo_info.mass)
		printf, f, string(form='(A12)','radius = '), string(format='(F4.2)', mo_info.radius)
		printf, f, string(form='(A12)','lum = '), string(format='(F6.4)', mo_info.lum)
		printf, f, string(form='(A12)','teff = '), string(format='(I4)', mo_info.teff)

		printf, f, string(form='(A12)','spectype = '), rw(mo_info.spectype)
		close, f
		free_lun, f
		save, filename=mo_dir() + 'mo_info.idl'
		mprint, '     saving mo_info.idl to ', mo_dir()
		mprint, done_string
	endif else begin
		mprint, skipping_string, 'star information is up to date!'
	endelse
	if keyword_set(verbose) and ~keyword_set(quick) then spawn, 'cat ' + mo_dir() + 'pos.txt ' + mo_dir() + 'mo_obs.txt ' + mo_dir() + 'mo_phys.txt'
	
  END