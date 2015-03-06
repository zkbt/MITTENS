PRO permit
	; when run, this loops through all files and makes sure they are all readable by the entire group
	procedure_prefix = '[permit.pro]'

;
	;spawn, 'chgrp -R exoplanet *'

	print, procedure_prefix,  'making sure the permissions are all set to 770, so other MEarthlings can see the data'
	print, procedure_prefix,  ' (this may take a while)'
	spawn, 'chmod -R g+rwx *'
	print, procedure_prefix,  ' All done! Thanks!'

END
