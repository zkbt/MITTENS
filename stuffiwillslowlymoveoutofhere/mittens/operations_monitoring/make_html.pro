PRO make_html
	spawn, 'ls plots/*.eps', eps_files
	png_files = eps_files
	for i=0, n_elements(eps_files)-1 do begin 
		this_eps = eps_files[i]
		this_png = this_eps
		print , 'epstopdf '+this_eps
		spawn , 'epstopdf '+this_eps
		strput, this_png, 'png', strpos(this_eps, 'eps')
		print , 'convert '+this_eps + ' ' + this_png		
		spawn , 'convert '+this_eps + ' ' + this_png
	endfor
END