PRO plot_stats

caldat, systime(/julian)-1, m, d, y
yesterday = long(string(y, m, d, format='(I4,I02,I02)'))
caldat, systime(/julian)-15, m, d, y
lastweek = long(string(y, m, d, format='(I4,I02,I02)'))

	print, 'everything.eps'
	plot_scopes, [20081001,yesterday], max_tel=8, seeing=8, stdcrms=100, ellipticity=0.3, filename='everything.eps'  
	print, 'last_week.eps'
	plot_scopes, [lastweek,yesterday], max_tel=8, seeing=8, stdcrms=100, ellipticity=0.3, filename='lastweek.eps'  
	months = [20081001,20081101,20081201, 20090101,20090201,20090301, 20090401, 20090501, 20090601, 20090701, 20090801, 20090901,20091001,20091101,20091201, 20100101,20100201,20100301, 20100401, 20100501, 20100601, 20100701, 20100801,20100901,20101001,20101101,20101201, 20110101,20110201,20110301, 20110401, 20110501, 20110601, 20110701, 20110801,20110901,20111001,20111101,20111201]
	for i=0, n_elements(months)-1 do begin
		if yesterday gt months[i] then begin; and yesterday lt months[i] + 100 then begin
			plot_scopes, [months[i], min([months[i+1], yesterday])], max_tel=8, seeing=8, stdcrms=100, ellipticity=0.3, filename="monthly_"+string(months[i], format='(I8)') + ".eps" 
			png = 'monthly_'+string(months[i], format='(I8)') + ".png" 
			png_sum = 'summary_monthly_'+string(months[i], format='(I8)') + ".png" 
			pdf = 'monthly_'+string(months[i], format='(I8)') + ".pdf" 
			pdf_sum = 'summary_monthly_'+string(months[i], format='(I8)') + ".pdf" 
			this_htm = 'plots/monthly_'+string(months[i], format='(I8)') + ".htm"
			openw, h, this_htm, /get_lun
			printf, h, '<html>'
			printf, h, '<body>'
			printf, h, '<font size=4>' + string(months[i], format='(I8)') + ' Monthly Stats<br></font>'
			printf, h, '<table><tr><td>'
			printf, h, '<a href="'+pdf+'">'
			printf, h, '<img src="'+png+'", border=0></a>'
			printf, h, '</td><td>'
			printf, h, '<a href="'+pdf_sum+'">'
			printf, h, '<img src="'+png_sum+'", border=0></a>'
			printf, h, '<table><tr><td>'
			printf, h, '</html>'
			printf, h, '</body>'
			close, h
		endif
	endfor
END