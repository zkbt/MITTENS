PRO compare_candidates
	c = load_joint_candidates()
	xplot, ysize=800, xsize=500
	smultiplot, [1,2], /init, xgap=0.02, ygap=0.05
	smultiplot, /dox
	loadct, 0, /silent
	plot, sqrt(c.old.chi),c.new.depth/c.new.depth_uncertainty,  psym=3, /iso, /xl, /yl, xr=[1,1000], yr=[1,100], xtitle=goodtex('Old (\chi^2)^{1/2}'), ytitle='New S/N'
	oplot, [1,1000],[1,1000]
	xyouts, sqrt(c.old.chi),c.new.depth/c.new.depth_uncertainty,strcompress(/remo, c.lspm), align=0.5, color=150
	oplot, sqrt(c.old.chi),c.new.depth/c.new.depth_uncertainty,  psym=3

	smultiplot	
	plot, c.old.period, c.new.period, xtitle='Old Best Period', ytitle='New Best Period', psym=3, /nodata, /iso, /xl, /yl, xr=[0.5, 20], yr=[0.5, 20], xs=3, ys=3
	;xyouts, c.old.period, c.new.period, strcompress(/remo, c.lspm), color=150
	oplot, c.old.period, c.new.period, psym=3
	
	smultiplot, /def
END