PRO comment_in_log
	common mearth_tools
	common this_star
	date = '"' + star_dir + strcompress(' ('+ strcompress(/remo, systime(/jul)) + ' = ' + systime() + ')') + ' by ' + username + '"'
	spawn, 'echo ' + date + ' >> '+star_dir + 'comments.log; echo "" >> ' + star_dir + 'comments.log; kwrite '+star_dir + 'comments.log'
	load_summary_of_comments
END