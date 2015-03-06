PRO oplot_box, xrange, yrange, thick=thick, linestyle=linestyle, color=color
	plots, [xrange, reverse(xrange), xrange[0]], [yrange[0], yrange, reverse(yrange)], thick=thick, linestyle=linestyle, color=color
END