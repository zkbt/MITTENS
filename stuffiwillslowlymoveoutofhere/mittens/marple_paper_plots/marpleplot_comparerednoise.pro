PRO marpleplot_comparerednoise, eps=eps, remake=remake
; demonstrate how to phase up multiple MarPLE's, in one succinct plot
	common mearth_tools
	common this_star

	if file_test(star_dir() + 'wgn_box_pdf.idl') eq 0 or file_test(star_dir() + 'rgn_box_pdf.idl') eq 0 or keyword_set(remake) then begin
		lc_to_pdf, /remake, /test, white=white
		lc_to_pdf, /remake, /redtest, white=white
	endif
	cleanplot
	filename = 'marpleplot_comparerednoise.eps'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=2, /inches, /color
	endif
	

	charsize = 0.6


	!p.charsize=charsize
	!x.margin=[12,3]
	symsize = 0.3

!y.margin=[5,11]

	restore, star_dir() + 'rgn_box_pdf.idl'
	plot_boxes, boxes,  red_variance=box_rednoise_variance, candidate=candidate, /extern, /demo, leg='simulated  LC with injected trends + red noise'

	!y.margin=[14,2]
	restore, star_dir() + 'wgn_box_pdf.idl'
	plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=candidate, /extern, /nobottom, /hold, /demo, leg='simulated LC with injected trends + white noise'
	
	

	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

; INTERPOLATE ONTO BOX GRID FOR TIMES TO SHOW WHAT THE MODEL LOOKS LIKE ON TOP OF THE DATA
END