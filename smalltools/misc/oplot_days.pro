PRO oplot_days, hjd, scale, top=top, bottom=bottom
   for i=0, n_elements(hjd)-2 do begin
       if hjd[i+1] - hjd[i] gt 0.3 then begin
	if not keyword_set(top) then oplot, [i,i]+0.5, [0.9*scale, 100], color=220, thick=1
        if not keyword_set(bottom) then oplot, [i,i]+0.5, [-0.9*scale, -100], color=220, thick=1
       endif
    endfor
END
