PRO estimate_occurrence, plot=plot, sensitivity_filename=sensitivity_filename

	for i=0, 1 do begin	
		print
		print
		if i eq 0 then begin
			coef = {k_R:1.0, alpha:-1.92, k_P:0.064, beta:0.27, P_0:7.0, gamma:2.6}
			radius_range = [2,4]
			period_range = [.5, 10]
			n_det = 1
			print, 'for planets with 2-4 Rearth, P<10 days'
		endif
		if i eq 1 then begin
			coef = {k_R:1.0, alpha:-1.92, k_P:0.002, beta:0.79, P_0:2.2, gamma:4.0, k_tot:1.0}			
			radius_range = [4,8]
			period_range = [.5, 10]
			n_det = 0
			print, 'for planets with 4-8 Rearth, P<10 days'
		endif
; 		if i eq 2 then begin
; 			coef = {k_R:1.0, alpha:-1.92, k_P:0.002, beta:0.79, P_0:2.2, gamma:4.0, k_tot:1.0}
; 			radius_range = [2.5,3]
; 			period_range = [.5, 3.0]
; 			n_det = 1
; 			print, 'for planets with 2.5 - 3 Rearth, P<3 days'
; 		endif
; 		if i eq 3 then begin
; 			coef = {k_R:1.0, alpha:-1.92, k_P:0.002, beta:0.79, P_0:2.2, gamma:4.0, k_tot:1.0}
; 			radius_range = [4,8]
; 			period_range = [.5, 3.0]
; 			n_det = 0
; 			print, 'for planets with 4-8 Rearth, P<3 days'
; 		endif
; 		if i eq 4 then begin
; 			coef = {k_R:1.0, alpha:-1.92, k_P:0.002, beta:0.79, P_0:2.2, gamma:4.0, k_tot:1.0}
; 			radius_range = [2,4]
; 			period_range = [.5, 10]
; 			n_det = 1
; 			print, 'for planets with 2-4 Rearth, P<10 days'
; 		endif

		int = integrate_sensitivity(radius_range =radius_range, coef=coef, plot=plot, period_range=period_range, n_det=n_det, sensitivity_filename=sensitivity_filename)
		printl

		tags = tag_names(coef)
		str =''
		for q =1, n_tags(coef)-1 do str += tags[q] + ' = ' + strcompress(/remo, coef.(q)) +', '
		print, '(the assumptions about the shape of the distribution are...)'
		print, str
		print	
;			say_occurrence_rate, int, n_det

		printl
		print
		print
		print
		print
		print
		print
	endfor


END