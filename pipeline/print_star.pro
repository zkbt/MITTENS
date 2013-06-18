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
	if file_test(star_dir +'lspm_info.idl') eq 0 or keyword_set(remake) eq 1 then begin
	;	if file_test(star_dir) eq 0 then file_mkdir, star_dir
		mprint, doing_string, 'printing star information to files'
		
		rah = long(lspm_info.ra/15)
		ram = long((lspm_info.ra/15 - rah)*60)
		ras = ((lspm_info.ra/15 - rah)*60 - ram)*60
		decd = long(lspm_info.dec)
		decm = long((lspm_info.dec - decd)*60)
		decs = ((lspm_info.dec - decd)*60-decm)*60
		pos_string = string(rah, format='(I02)') + ":"+ string(ram, format='(I02)')+ ":"+ string(ras, format='(F04.1)') + '  +'+string(decd, format='(I02)')+ ":"+ string(decm, format='(I02)')+ ":"+ string(decs, format='(F04.1)');+ "  (J2000)"
	
		openw, f, /get_lun, star_dir + 'demo.txt'
		printf, f, '<b>'+star_dir+'</b>'
		printf, f, pos_string
		close, f
		free_lun, f
	
		openw, f, /get_lun, star_dir+'pos.txt'
		printf, f, pos_string
		free_lun, f
	
		link = 'http://simbad.u-strasbg.fr/simbad/sim-id?Ident='+lspm_info.names+ '&NbIdent=1&Radius=2&Radius.unit=arcmin&submit=submit+id'
		openw, f, /get_lun, star_dir + 'lspm_obs.txt'
		printf, f, '<a href="' + link + '" style="color: black; font-weight:bold">' + lspm_info.names + '</a>'
		printf, f, 'px = ', string(format='(F5.3)', lspm_info.parallax), ' +/- ', string(format='(F5.3)', lspm_info.err_parallax)
		printf, f, 'pm = ', strcompress(string(format='(F5.2)', lspm_info.pmra)), ' ', string(format='(F5.2)', lspm_info.pmdec)
		printf, f, 'V = ', string(format='(F4.1)', lspm_info.v)
		printf, f, 'J = ', string(format='(F4.1)', lspm_info.j)
		printf, f, 'H = ', string(format='(F4.1)', lspm_info.h)
		printf, f, 'K = ', string(format='(F4.1)', lspm_info.k)
		close, f
		free_lun, f
	
		openw, f, /get_lun, star_dir + 'lspm_phys.txt'
		printf, f, 'mass = ', string(format='(F4.2)', lspm_info.mass)
		printf, f, 'radius = ', string(format='(F4.2)', lspm_info.radius)
		printf, f, 'lum = ', string(format='(F6.4)', lspm_info.lum)
		printf, f, '<h2>M' + string(format='(F3.1)', lspm_info.sp) + '</h2>'
		close, f
		free_lun, f
		save, filename=star_dir + 'lspm_info.idl'
		mprint, '     saving lspm_info.idl to ', star_dir
		mprint, done_string
	endif else begin
		mprint, skipping_string, 'star information is up to date!'
	endelse
	if keyword_set(verbose) and ~keyword_set(quick) then spawn, 'cat ' + star_dir + 'pos.txt ' + star_dir + 'lspm_obs.txt ' + star_dir + 'lspm_phys.txt'
	
  END