PRO lightcurves_into_marples, remake=remake

	common mearth_tools
	mprint, /line
	mprint, tab_string, 'lightcurves_into_marples.pro is taking the lightcurves located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating MarPLES (= transit depth probability distributions) from them'
	mprint, /line

	display, /off
	verbose, /on
	interactive, /off

	f = file_search('ls*/', /mark)
	for i=0, n_elements(f)-1 do begin
		lspmn = long(stregex(f[i], '[0-9]+', /ext))
		marplify, lspmn, remake=remake
	endfor
END
