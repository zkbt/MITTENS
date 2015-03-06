FUNCTION jxpar, header, tag, n_array, error=error
	error = 0
	; like sxpar, but can handle >1000 repeat entries in headers
	i = where(strmatch(header, tag) or strmatch(header, 'HIERARCH '+tag), n)
	if not keyword_set(n_array) then n_array = n
	if n eq 0 then begin
		print, '      JXPAR + no tag ', tag, " found! returing 0's"
		error = 1
		return, fltarr(n_array)
	endif
	indices = long(stregex(/ext, stregex(/ext, header[i], '.*='), '[0-9]+')) - 1
	values = strarr(n_array)
	values[indices] = stregex(/ext, stregex(/ext, header[i], '=.*'), '[^=].[^/]*') 
	return, values
END

PRO make_lspm_directory, filename, remake=remake
;+
; NAME:
;	GET_JONATHANS_LIGHTCURVES
; PURPOSE:
;	take one of Jonathan's files, load all the M dwarf light curves in it into MITTENS (this function is called by load_star.pro)
; CALLING SEQUENCE:
;	get_jonathans_lightcurves, filename, remake=remake
; INPUTS:
;	filename = the (absolute) filename of one of Jonathan's light curve files
; KEYWORD PARAMETERS:
;	/remake = redo everything, whether or not its already been done
; OUTPUTS:
;	writes lots of files to MITTENS directories
; RESTRICTIONS:
; EXAMPLE:
;	get_jonathans_lightcurves, "/data/mearth2/2008-2010-iz/reduced/tel01/master/lspm1186_lc.fits', remake=remake
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
	; need a reduced data directory for each year
	possible_years = [2008,2009,2010,2011]
	reduced_dir = ['/data/mearth2/2008-2010-iz/reduced/','/data/mearth2/2008-2010-iz/reduced/', '/data/mearth2/2010-2011-I/reduced/', '/data/mearth1/reduced/']
	yearly_filters = ['iz', 'iz', 'I', 'iz']
	
	; set working directory; on CfA network or on laptop?
	;if getenv('HOME') eq '/Users/zachoryberta' then working_dir = '/Users/zachoryberta/mearth/' else 
	working_dir = '/pool/eddie1/zberta/mearth_test/'

	; read in FITS
	fi = file_info(filename)



	if fi.exists ne 0 and fi.size ne 0 then begin
		fits_lc = mrdfits(filename, 1, header_lc, status=status, /silent)
		; if successfully read in, then continue to generate an IDL lightcurve		
		if status eq 0 then begin
			print,  ' extracting all M dwarf light curves from ', filename
			jmi_file_prefix = strmid(filename, 0, strpos(filename, '_lc.fits'))
			start = stregex(jmi_file_prefix, '(lspm[0-9]+)+', length=length)
			lspm_section = strmid(jmi_file_prefix, start, length)
			anything_left = strmid(jmi_file_prefix, start + length, 1000)
			tel = uint(stregex(stregex(filename, 'tel[0-9]+', /extract), '[0-9]+', /extract))
	
		
			if anything_left ne '' then suffix = anything_left else suffix = '' 
	
			if n_elements(fits_lc[0].flux) gt 1 then begin

				; pick out the M dwarf targets from the field
				i_targets = where(fits_lc.class eq 9, n_targets)
					
				; make and store lightcurves for every LSPM in the field
				for j=0, n_targets-1 do begin
					i_target = i_targets[j]

					; how long a lightcurve?
					n_datapoints =  n_elements(fits_lc[i_target].hjd)
				
					; set up directories and prefixes
					if not keyword_set(suffix) then suffix=''
					if keyword_set(allow_all) then suffix += '_untrimmed'
					if total(strmatch(tag_names(fits_lc), 'LSPM')) eq 0 then begin
						lspm_string = stregex(jmi_file_prefix, 'lspm[0-9]+', /extract) 
					endif else begin
						lspm_string = 'lspm' + strcompress(/remove_all, fits_lc[i_target].lspm)
					endelse
					lspm = long(stregex(lspm_string, '[0-9]+', /extract))
					tel_string = 'tel0'+strcompress(/remove_all, tel)
					tel = long(stregex(/ex, stregex(/ex, jmi_file_prefix, 'tel[0-9]+'), '[0-9]+'))

					; make the LSPM directory!
					lspm_dir = 'lspm'+string(lspm, format='(I4)') + '/'
					file_mkdir, lspm_dir

					; to make it easier to look things up later....
					openw, f, lspm_dir + 'jmi_file_prefix.txt', /get_lun, /append
					printf, f, jmi_file_prefix
					close, f
					free_lun, f
				endfor
			endif
		endif else print, " :-0 couldn't read " + filename
	endif else print, " :-0 couldn't read " + filename

END
