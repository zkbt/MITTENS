PRO mittens_permissions
	common mearth_tools
;	files =  getenv('MITTENS_DATA') + ['*','*/*','*/*/*', '*/*/*/*']
;	file_chmod, files, '700'; u_read=1, u_write=1, u_execute=1, g_read=1, g_write=1, g_execute=1, o_read=0, o_write=0, o_execute=0
	mprint, tab_string, doing_string, "updating permissions so everyone can see what you've done"
	spawn, 'chmod -R 770 $MITTENS_DATA/* '
END