; if keyword_set(star_dir) then delvar, star_dir
; if keyword_set(lspm_info) then delvar, lspm_info
; common this_star
;f = file_search(star_dir + '*.idl')
;for i=0, n_elements(f)-1 do restore, f[i]
star_dir = star_dir()
restore, star_dir + 'target_lc.idl'
restore, star_dir + 'box_pdf.idl'
restore, star_dir + 'aperture.idl'
restore, star_dir + 'field_info.idl'
restore, star_dir + 'inflated_lc.idl'
restore, star_dir + 'flares_pdf.idl'
restore, star_dir + 'ext_var.idl'
restore, star_dir + 'cleaned_lc.idl'
; restore, star_dir + 'medianed_lc.idl'
; restore, star_dir + 'ext_var.idl'
; restore, star_dir + 'superfit.idl'
; restore, star_dir + 'target_lc.idl'
; restore, star_dir + 'blind/best/candidate.idl'
