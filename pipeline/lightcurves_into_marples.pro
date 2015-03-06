PRO lightcurves_into_marples, remake=remake, start=start

	common mearth_tools
	mprint, /line
	mprint, tab_string, 'lightcurves_into_marples.pro is taking the lightcurves located in'
	mprint, tab_string, tab_string, getenv('MITTENS_DATA')
	mprint, tab_string, 'and generating MarPLES (= transit depth probability distributions) from them'
	mprint, /line

	display, /off
	verbose, /on
	interactive, /off

	f = file_search('mo*/', /mark)
	if n_elements(start) eq 0 then start = 0
	for i=start*n_elements(f), n_elements(f)-1 do begin
		mo = name2mo(f[i])
		marplify, mo, remake=remake
	endfor
END
