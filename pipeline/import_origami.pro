PRO import_origami, dont=dont
;+
; NAME:
;	outsource_folding
; PURPOSE:
;	convert all MarPLES to text files, then scp them to MIT
;		(will hopefully send only those that need to be folded_
; CALLING SEQUENCE:
; 	outsource_folding
	common mearth_tools
	mprint, /line
	mprint, tab_string, 'import_origami.pro is importing phase-folding spectra from MIT'
	mprint, /line


	; download the origami spectra from MIT
	file_mkdir, 'origami_received'
	if ~keyword_set(dont) then spawn, 'rsync -trv zkbt@antares.mit.edu:/corscorpii/d1/zkbt/mearth/results/ origami_received/'

	; make sure their group permissions are set to exoplanet (this seems to work only from zach's directory)
	spawn, 'chgrp -R exoplanet origami_received/*', error
	spawn, 'chmod 660 origami_received/*', error
  
	; compile a list of all the files that have been received
	f = file_search('origami_received/*')
	mo = name2mo(f)

	; loop through these files and move them to their proper directories
	for i=0, n_elements(f)-1 do begin
		new_file = mo_prefix + mo[i]+'/combined/boxes_all_durations.txt.bls'
		print, 'moving ', f[i], ' to ', new_file
		file_move, f[i], new_file, /over
	endfor
END