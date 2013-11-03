PRO make_ct

print, " I'm making some new color tables, because the default IDL ones are mostly terrible"
print, " A file called zkb_colors.tbl will be placed in your home directory"
print, " To use it, run something like [loadct, 56, file='~/zkb_colors.tbl'] from IDL"

if file_test('~/zkb_colors.tbl') eq 0 then file_copy, !DIR + '/resource/colors/colors1.tbl', '~/zkb_colors.tbl'
forward = indgen(256)
backward = reverse(forward)
on = intarr(256)+255
half = on/2
off = intarr(256)

modifyct, 41, 'black',  off,off, off, file='~/zkb_colors.tbl'
modifyct, 42, 'red',  on, forward,  forward, file='~/zkb_colors.tbl'
modifyct, 43, 'red (reverse)',  on, backward, backward, file='~/zkb_colors.tbl'


modifyct, 44, 'green', forward,   on, forward, file='~/zkb_colors.tbl'
modifyct, 45, 'green (reverse)',  backward, on,  backward, file='~/zkb_colors.tbl'

modifyct, 46, 'blue', forward,   forward,on,  file='~/zkb_colors.tbl'
modifyct, 47, 'blue (reverse)',  backward,   backward, on, file='~/zkb_colors.tbl'

modifyct, 48, 'aqua', forward,   on,on,  file='~/zkb_colors.tbl'
modifyct, 49, 'aqua (reverse)',  backward,   on, on, file='~/zkb_colors.tbl'

modifyct, 50, 'yellow', on,   on, forward, file='~/zkb_colors.tbl'
modifyct, 51, 'yellow (reverse)',  on, on,  backward, file='~/zkb_colors.tbl'

modifyct, 52, 'pink', on, forward,  on, file='~/zkb_colors.tbl'
modifyct, 53, 'pink (reverse)',  on, backward, on, file='~/zkb_colors.tbl'

modifyct, 54, 'orange', on,   (on+forward)/2, forward, file='~/zkb_colors.tbl'
modifyct, 55, 'orange (reverse)',  on, (on+backward)/2,  backward, file='~/zkb_colors.tbl'

modifyct, 56, 'prochloro',    (on+forward)/2, on,forward, file='~/zkb_colors.tbl'
modifyct, 57, 'prochloro (reverse)',   (on+backward)/2, on, backward, file='~/zkb_colors.tbl'

modifyct, 58, 'ocean',    forward,(on+forward)/2, on, file='~/zkb_colors.tbl'
modifyct, 59, 'ocean (reverse)',   backward, (on+backward)/2, on,  file='~/zkb_colors.tbl'

; modifyct, 60, 'purple',   (on+forward)/2, forward, (on +forward)/2, file='~/zkb_colors.tbl'
; modifyct, 61, 'purple (reverse)',   (on+backward)/2, backward, (on + backward)/2, file='~/zkb_colors.tbl'

name = 'purple'
r = [150, 255]
g = [0, 255]
b = [245, 255]
modifyct, 60, name, r[0] + findgen(256)/256*(r[1] - r[0]),  g[0] + findgen(256)/256*(g[1] - g[0]),  b[0] + findgen(256)/256*(b[1] - b[0]), file='~/zkb_colors.tbl'
modifyct, 61, name +' (reverse)', reverse(r[0] + findgen(256)/256*(r[1] - r[0])),  reverse(g[0] + findgen(256)/256*(g[1] - g[0])), reverse( b[0] + findgen(256)/256*(b[1] - b[0])), file='~/zkb_colors.tbl'



name = 'orange'
n = 54
r = [245, 255]
g = [100, 255]
b = [6, 255]
modifyct, n, name, r[0] + findgen(256)/256*(r[1] - r[0]),  g[0] + findgen(256)/256*(g[1] - g[0]),  b[0] + findgen(256)/256*(b[1] - b[0]), file='~/zkb_colors.tbl'
modifyct, n+1, name +' (reverse)', reverse(r[0] + findgen(256)/256*(r[1] - r[0])),  reverse(g[0] + findgen(256)/256*(g[1] - g[0])), reverse( b[0] + findgen(256)/256*(b[1] - b[0])), file='~/zkb_colors.tbl'

name = 'fuschia'
n = 62
r = [245, 255]
g = [4, 255]
b = [81, 255]
modifyct, n, name, r[0] + findgen(256)/256*(r[1] - r[0]),  g[0] + findgen(256)/256*(g[1] - g[0]),  b[0] + findgen(256)/256*(b[1] - b[0]), file='~/zkb_colors.tbl'
modifyct, n+1, name +' (reverse)', reverse(r[0] + findgen(256)/256*(r[1] - r[0])),  reverse(g[0] + findgen(256)/256*(g[1] - g[0])), reverse( b[0] + findgen(256)/256*(b[1] - b[0])), file='~/zkb_colors.tbl'




name = 'bw'
n =64
r = [0, 255]
g = [0, 255]
b = [0, 255]
modifyct, n, name, r[0] + findgen(256)/256*(r[1] - r[0]),  g[0] + findgen(256)/256*(g[1] - g[0]),  b[0] + findgen(256)/256*(b[1] - b[0]), file='~/zkb_colors.tbl'
modifyct, n+1, name +' (reverse)', reverse(r[0] + findgen(256)/256*(r[1] - r[0])),  reverse(g[0] + findgen(256)/256*(g[1] - g[0])), reverse( b[0] + findgen(256)/256*(b[1] - b[0])), file='~/zkb_colors.tbl'




name = 'black-to-prochloro'
n =66
r = [255, 0]
g = [110, 0]
b = [10, 255]
modifyct, n, name, r[0] + findgen(256)/256*(r[1] - r[0]),  g[0] + findgen(256)/256*(g[1] - g[0]),  b[0] + findgen(256)/256*(b[1] - b[0]), file='~/zkb_colors.tbl'
modifyct, n+1, name +' (reverse)', reverse(r[0] + findgen(256)/256*(r[1] - r[0])),  reverse(g[0] + findgen(256)/256*(g[1] - g[0])), reverse( b[0] + findgen(256)/256*(b[1] - b[0])), file='~/zkb_colors.tbl'






loadct, file='~/zkb_colors.tbl', get_names=color_names
n = n_elements(color_names)
set_plot, 'ps'
device, filename='~/zkb_colors.eps', /color, /encap, xsize=7.5, ysize=11, /inches
!x.margin=[5,5]
!y.margin=[5,5]
!p.charsize=0.5
n_cols=2
n_rows = float(n)/n_cols
if n_rows mod 1 eq 0.5 then n_rows += 0.5
n_rows = uint(n_rows)
multiplot, [n_cols,n_rows], /init, xgap=0.02
for ct=0 ,n-1 do begin
	multiplot
	@psym_circle
	loadct, 0, /silent
;	window, xsize=2000, ysize=100
	loadct, get_names=color_names, file='~/zkb_colors.tbl'
	plot, findgen(256), fltarr(256), /nodata, xs=5, ys=4, title=color_names[ct] + ' = ' + strcompress(/remo, ct), yrange=[-0.5, 0.1]
	loadct, ct, file='~/zkb_colors.tbl'
	plots, findgen(256), fltarr(256), psym=8, symsize=0.8, color=findgen(256)
endfor
multiplot, /def
device, /close
set_plot, 'x'
epstopdf, '~/zkb_colors'
END