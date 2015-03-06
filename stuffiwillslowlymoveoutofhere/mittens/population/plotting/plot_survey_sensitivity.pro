PRO plot_survey_sensitivity;, year=year, tel=tel, radius_range=radius_range
; if keyword_set(year) then label += 'ye'+string(format='(I02)', year mod 100) + '_'
; if keyword_set(tel) then label += 'te'+string(format='(I02)', tel) + '_'
; if keyword_set(radius_range) then label += 'radius'+string(format='(I02)', 100*radius_range[0])+'to'+string(format='(I02)', 100*radius_range[1]) + '_'

  set_plot, 'ps'
  common mearth_tools
  f = file_search('population/survey_sensitivity*.idl')

for k=0, n_elements(f)-1 do begin
	restore, f[k]
	label = f[k]
  !p.charthick=4
  !x.thick=4
  !y.thick=4

  device, filename=label+'sensitivity.eps', /encapsulated, /color, /inches, xsize=7.5, ysize=7.5
  !p.charsize=1.4
  n_radii = n_elements(radii)
  radii_color =  (1+indgen(n_radii))*160.0/n_radii  
  radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90
  n = n_elements(sensitivity.period.grid)
  loadct, 0
	!x.margin=[8,8]
  multiplot, /init, [2,2]
multiplot
multiplot
plot, [0], /nodata, xs=4, ys=4

  subset =indgen(n_elements(sensitivity.period.detection[0,*])); [0,2,4]

         al_legend, box=0, thick=5, color=radii_color, goodtex(string(format='(F4.1)', radii) + ' R_{Earth}'), /top, /right, linestyle=subset

  multiplot
  plot, sensitivity.period.grid, sensitivity.period.detection[*,0], /xstyle, /ystyle, xrange=[0.6,20], xtitle='Period (days)', ytitle=goodtex('MEarth Sensitivity (# of planets)'), /ylog, /xlog, yrange=[1, 100], /nodata, title='                      '+label
  loadct, file='~/zkb_colors.tbl',0
  for i=0,n_elements(subset)-1 do begin
    m = subset[i]
    x = [sensitivity.period.grid[0],sensitivity.period.grid[0],sensitivity.period.grid,sensitivity.period.grid[n-1],sensitivity.period.grid[n-1], sensitivity.period.grid]
    y = [sensitivity.period.detection[0,m],sensitivity.period.detection[0,m],sensitivity.period.detection[*,m],sensitivity.period.detection[n-1,m],sensitivity.period.detection[n-1,m], sensitivity.period.detection[*,m]]
   ; polyfill, x, y, color=radii_color[m], noclip=0, /line_fill, orientation=radii_angle[m], spacing=0.1
  ;  polyfill, x, y, color=radii_color[m], noclip=0, /line_fill, orientation=90, spacing=0.1

    oplot, sensitivity.period.grid, sensitivity.period.detection[*,m], color=radii_color[m], thick=3, linestyle=subset[i]
    oplot, sensitivity.period.grid, sensitivity.period.detection[*,m], color=radii_color[m], thick=3, linestyle=subset[i]
   endfor
  ;      xyouts, [10.5,7, 5]-2, [9,4,2]+2, goodtex(string(format='(F3.1)', radii[subset]) + ' R_{Earth}'), alignment=0.5, orientation=-45
   
multiplot
  plot, sensitivity.temp.grid, sensitivity.temp.detection[*,0], /xstyle, /ystyle, xtitle='Equilibrium Temperature (K)', /ylog, yrange=[1, 100], xrange=[250,max(sensitivity.temp.grid)], /nodata;, title=label
;axis, yaxis=1, ytitle='Planets / '
  for i=0,n_elements(subset)-1 do begin
    m = subset[i]
    x = [sensitivity.temp.grid[0],sensitivity.temp.grid[0],sensitivity.temp.grid,sensitivity.temp.grid[n-1],sensitivity.temp.grid[n-1], sensitivity.temp.grid]
    y = [sensitivity.temp.detection[0,m],sensitivity.temp.detection[0,m],sensitivity.temp.detection[*,m],sensitivity.temp.detection[n-1,m],sensitivity.temp.detection[n-1,m], sensitivity.temp.detection[*,m]]
 ;   polyfill, x, y, color=radii_color[m], noclip=0, /line_fill, orientation=radii_angle[m], spacing=0.1
 ;   polyfill, x, y, color=radii_color[m], noclip=0, /line_fill, orientation=0, spacing=0.1
 
    oplot, sensitivity.temp.grid, sensitivity.temp.detection[*,m], color=radii_color[m], thick=3, linestyle=subset[i]
    oplot, sensitivity.temp.grid, sensitivity.temp.detection[*,m], color=radii_color[m], thick=3, linestyle=subset[i]
  ;      al_legend, box=0, linestyle=0, thick=3, charthick=1, color=radii_color, goodtex(string(format='(F3.1)', radii) + ' R_{Earth}'), /bottom, /right
  endfor
 ;   xyouts, [300,350, 400], [8.5,4.5,3], goodtex(string(format='(F3.1)', radii[subset]) + ' R_{Earth}'), alignment=0.5, orientation=50
 


  multiplot, /def
  device, /close
 epstopdf,label+'sensitivity.eps'
endfor
  set_plot, 'x'
  

  
  
END