PRO marpleplot_inject
; demonstrate how to phase up multiple MarPLE's, in one succinct plot
	common mearth_tools
	common this_star

	restore, star_dir + 'box_pdf.idl'
	filename='marpleplot_inject'
	if keyword_set(eps) then begin
		set_plot, 'ps'
		device, filename=filename, /encap, xsize=7.5, ysize=2, /inches, /color
	endif
	!p.charsize=0.6
			!x.margin = [60,12]
			!y.margin=[16, 2]
			plot_boxes, boxes, red_variance=box_rednoise_variance, candidate=candidate
	if keyword_set(eps) then begin
		device, /close
		set_plot, 'x'
		epstopdf, filename
	endif

; INTERPOLATE ONTO BOX GRID FOR TIMES TO SHOW WHAT THE MODEL LOOKS LIKE ON TOP OF THE DATA
END