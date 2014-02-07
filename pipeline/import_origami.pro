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


	file_mkdir, 'origami_received'
	if ~keyword_set(dont) then spawn, 'rsync -rv zkbt@antares.mit.edu:/corscorpii/d1/zkbt/mearth/results/ origami_received/'

	f = file_search('origami_received/*')

	ls = long(stregex(/ext, stregex(/ext, f, 'ls[0-9]+'), '[0-9]+'))
	for i=0, n_elements(f)-1 do begin
		new_file = 'ls'+ string(form='(I04)', ls[i]) + '/combined/boxes_all_durations.txt.bls'
		print, 'moving ', f[i], ' to ', new_file
		file_move, f[i], new_file, /over
	endfor
END