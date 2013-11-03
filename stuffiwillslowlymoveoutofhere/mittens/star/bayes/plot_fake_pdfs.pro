PRO plot_fake_pdfs, i
	if not keyword_set(i) then i=0
	common mearth_tools
	common this_star
	star_dir = stregex(/ext, star_dir, 'ls[0-9]+/ye[0-9]+/te[0-9]+/') + 'fake/'


	restore, star_dir + 'injected_and_recovered.idl'
	;tags = [0,3,4,8,9]
;	i=0
	xplot, i+1, xsize=800, ysize=800, title='injected_'+string(format='(I2)', 10*radii[i])+'rearth'
	cloud = create_struct('injected_'+string(format='(I2)', 10*radii[i])+'rearth', injected[ where(injected.radius eq radii[i])], 'recovered_'+string(format='(I2)', 10*radii[i])+'rearth', recovered[ where(recovered.radius eq radii[i])])
	big_cloud = cloud
	plot_ndpdf,  cloud, /mult, psym=3
	if question('pause here?', /int) then stop
; 
;  	i = 1
; 	xplot, i+1, xsize=800, ysize=800, title='injected_'+string(format='(I2)', 10*radii[i])+'rearth'
; 	cloud = create_struct('injected_'+string(format='(I2)', 10*radii[i])+'rearth', injected[ where(injected.radius eq radii[i])], 'recovered_'+string(format='(I2)', 10*radii[i])+'rearth', recovered[ where(recovered.radius eq radii[i])])
; 	big_cloud = create_struct(big_cloud, cloud)
; 	plot_ndpdf,  cloud, /mult, tags=tags
; 
; 	i = 4
; 	xplot, i+1, xsize=800, ysize=800, title='injected_'+string(format='(I2)', 10*radii[i])+'rearth'
; 	cloud = create_struct('injected_'+string(format='(I2)', 10*radii[i])+'rearth', injected[ where(injected.radius eq radii[i])], 'recovered_'+string(format='(I2)', 10*radii[i])+'rearth', recovered[ where(recovered.radius eq radii[i])])
; 	big_cloud = create_struct(big_cloud, cloud)
; 	plot_ndpdf,  cloud, /mult, tags=tags
; 
; 	plot_ndpdf,  big_cloud, /mult, color_tables=[48,46, 56, 44, 52, 60], tags=tags
END