PRO permit

;	print, "making sure the group owner of all files I created are set to exoplanet"
;	print, ' (this may take a while)'
;
	;spawn, 'chgrp -R exoplanet *'

	print, 'making sure the permissions are all set to 770, so other MEarthlings can see the data'
	print, ' (this may take a while)'
	spawn, 'chmod -R g+rwx *'
	print, ' All done! Thanks!'
	
END