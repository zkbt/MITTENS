PRO make_stats, show_plot=show_plot, pause=pause, remake=remake

caldat, systime(/julian)-1, m, d, y
yesterday = string(y, m, d, format='(I4,I02,I02)')
caldat, systime(/julian)-60, m, d, y
lastweek = string(y, m, d, format='(I4,I02,I02)')
;lastweek = '20091001'
if keyword_set(remake) then lastweek = '20081001'
print, 'UPDATING THE STATUS FILES FOR ', [lastweek, yesterday]
for i=1,8 do begin
	make_days, long([lastweek, yesterday]), i
;	q= make_messylc(i, 3, .2, show_plot=show_plot, pause=pause)
end


END