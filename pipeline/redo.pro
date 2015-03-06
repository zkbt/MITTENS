PRO redo, mo, bulldoze=bulldoze, remake=remake, nofold=nofold
	common mearth_tools
	if n_elements(mo) eq 0 then mo = name2mo(mo_dir())
	mprint, /line
	mprint, tab_string, 'redo.pro is re-analyzing mo' + rw(mo) + ' in light of new information'
	mprint, /line

	display, /off
	verbose, /on
	interactive, /off

	marplify, mo, bulldoze=bulldoze, remake=remake
	if ~keyword_set(nofold) then call_origami_bot, bulldoze=bulldoze
END
