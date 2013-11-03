	cd, '/pool/eddie1/zberta/mearth/stats/'
	make_stats, /show_plot, pause=1
	plot_stats
	make_html
;	spawn, 'rsync index.html mearth@mearth.sao.arizona.edu:/var/www/html/stats/index.html -vz'
;	spawn, 'rsync plots mearth@mearth.sao.arizona.edu:/var/www/html/stats/ -dvrz'
	spawn, 'cp -v index.html /data/wdocs/zberta/www-docs/stats/.'
	spawn, 'cp -v plots/*.png /data/wdocs/zberta/www-docs/stats/plots/.'
	spawn, 'cp -v plots/*.pdf /data/wdocs/zberta/www-docs/stats/plots/.'
