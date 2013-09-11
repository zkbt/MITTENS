PRO redo, ls, bulldoze=bulldoze, remake=remake, nofold=nofold
	common mearth_tools
	mprint, /line
	mprint, tab_string, 'redo.pro is re-analyzing lspm' + rw(ls) + ' in light of new information'
	mprint, /line

	display, /off
	verbose, /on
	interactive, /off

	marplify, ls, bulldoze=bulldoze, remake=remake
	if ~keyword_set(nofold) then call_origami_bot, bulldoze=bulldoze
END
