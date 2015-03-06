set_star, /ran, n=100
restore, star_dir() + 'box_pdf.idl' 
plot_binned, boxes.rescaling, boxes.depth/boxes.depth_uncertainty, psym=1, xr=[.9, 2.7], /xs, xtitle='White Noise Rescaling Factor', ytitle='Transit Depth S/N'
hline, [-1,1], linestyle=1
