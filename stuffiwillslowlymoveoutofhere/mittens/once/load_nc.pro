	; SQL query only seems to work in IDL7.0
	; (run after saying)
	; setenv IDL_DIR /opt/idl/idl_7.0
	; setenv IDL_DLM_PATH /data/mearth1/db/idl
	; setenv PGSERVICE mearth

	nc_query = "select * from nc;"
	nc = pgsql_query(nc_query, /verb) 

	nc_names_query = "select * from nc_names;"
	nc_names = pgsql_query(nc_names_query, /verb) 

	nc_phot_query = "select * from nc_phot;"
	nc_phot = pgsql_query(nc_phot_query, /verb) 

	nc_plx_query = "select * from nc_plx;"
	nc_plx = pgsql_query(nc_plx_query, /verb) 

	nc_prot_query = "select * from nc_prot;"
	nc_prot = pgsql_query(nc_prot_query, /verb) 

	nc_phot_query = "select * from nc_phot;"
	nc_phot = pgsql_query(nc_phot_query, /verb) 

	nc_spectro_query = "select * from nc_spectro;"
	nc_spectro = pgsql_query(nc_spectro_query, /verb) 

	nc_src_query = "select * from nc_src;"
	nc_src = pgsql_query(nc_src_query, /verb) 

	save, nc, nc_names, nc_plx, nc_prot, nc_phot, nc_spectro, nc_src, filename='nc_inprogress.idl'
