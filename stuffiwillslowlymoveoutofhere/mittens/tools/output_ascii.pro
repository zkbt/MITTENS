PRO ascii_lc, lc, filename
	openw, lun, /get_lun, filename
	for i=0, n_elements(lc) -1 do printf, lun, string(format='(D13.7)', lc[i].hjd), '   ', string(format='(F8.5)', lc[i].flux),'   ', string(format='(F8.5)', lc[i].fluxerr)
	close, lun

END
PRO output_ascii
	common mearth_tools
	common this_star
	
	restore, star_dir + 'blind/best/candidate.idl'
	restore, star_dir + 'target_lc.idl'
	ascii_lc, target_lc, star_dir + 'target_lc.txt'
	ascii_lc, phase_lc(target_lc, candidate), star_dir + 'phased_target_lc.txt'
;	spawn, 'cat '+star_dir + 'target_lc.txt'
;	spawn, 'cat '+star_dir + 'phased_target_lc.txt'

	restore, star_dir + 'blind/best/candidate.idl'
	restore, star_dir + 'decorrelated_lc.idl'
	ascii_lc, decorrelated_lc, star_dir + 'decorrelated_lc.txt'
	ascii_lc, phase_lc(decorrelated_lc, candidate), star_dir + 'phased_decorrelated_lc.txt'
;	spawn, 'cat '+star_dir + 'decorrelated_lc.txt'
;	spawn, 'cat '+star_dir + 'phased_decorrelated_lc.txt'

	restore, star_dir + 'blind/best/candidate.idl'
	restore, star_dir + 'medianed_lc.idl'
	ascii_lc, medianed_lc, star_dir + 'medianed_lc.txt'
	ascii_lc, phase_lc(medianed_lc, candidate), star_dir + 'phased_medianed_lc.txt'
;	spawn, 'cat '+star_dir + 'medianed_lc.txt'
;	spawn, 'cat '+star_dir + 'phased_medianed_lc.txt'

	print, 'output ascii light curves to ', star_dir
	
END

