; FUNCTION dfdlogp, coef, periods
; 	return, coef.k_P*period^coef.beta*(1-exp(-(periods/coef.P_0)^coef.gamma))
; END

PRO plots_for_courtney, trigger=trigger, cutoff;, year=year, tel=tel, radius_range=radius_range
; if keyword_set(year) then label += 'ye'+string(format='(I02)', year mod 100) + '_'
; if keyword_set(tel) then label += 'te'+string(format='(I02)', tel) + '_'
; if keyword_set(radius_range) then label += 'radius'+string(format='(I02)', 100*radius_range[0])+'to'+string(format='(I02)', 100*radius_range[1]) + '_'

  set_plot, 'ps'
  common mearth_tools
if ~keyword_set(cutoff) then cutoff = 8
filename ='population/survey_sensitivity_'
if keyword_set(trigger) then filename += 'trigger_'
if keyword_set(year) then filename += 'ye'+string(format='(I02)', year) + '_'
if keyword_set(tel) then filename += 'te'+string(format='(I02)', tel)+ '_'
if keyword_set(lspm) then filename +='ls'+string(format='(I04)', lspm)+ '_'
filename += strcompress(/remo, cutoff) + 'cutoff'
filename += '.idl'
  f = file_search(filename)
restore, f
cleanplot

  !p.charthick=3

  !x.thick=3
  !y.thick=3
label = 'population/'+rw(cutoff)+'sigma_'
if keyword_set(trigger) then label += 'trigger_'
  device, filename=label+'radii.eps', /encapsulated, /color, /inches, xsize=10.0, ysize=6
	plot, [0],xcharsize=2, ycharsize=2, thick=8, xthick=3, ythick=3, xtitle='Stellar Radius (solar radii)', ytitle='# of Stars Observed', ymargin=[10,5], xmargin=[15, 5], xrange=[0.08, 1.0], /nodata,  yr=[0,500]
	loadct, 39
	plothist, /over, color=250, cloud.radius, bin=0.05, xcharsize=2, ycharsize=2, thick=6
	
device, /close
epstopdf, label+'radii.eps'

; 
;   device, filename=label+'temps.eps', /encapsulated, /color, /inches, xsize=10.0, ysize=6
; 	@psym_circle
; 	plot[0],xcharsize=2, ycharsize=2, thick=8, xthick=3, ythick=3, xtitle='Stellar Radius (solar radii)', ytitle='Stellar Effective Temperature', ymargin=[10,5], psym=8, /yno
; 	
; device, /close
; epstopdf, label+'temps.eps'
; 


  device, filename=label+'sensitivity.eps', /encapsulated, /color, /inches, xsize=10, ysize=5
  !p.charsize=1.1
!x.charsize=1.2
!y.charsize=1.2
  n_radii = n_elements(radii)
  radii_color =  (1+indgen(n_radii))*250.0/n_radii  
  radii_angle = 90*ones(n_radii);randomu(seed, n_radii)*90
  n = n_elements(sensitivity.period.grid)
  loadct, 39
	!x.margin=[15,4]
	!y.margin=[6,2]
  smultiplot, /init, [2,1], xgap=0


  subset =indgen(n_elements(sensitivity.period.detection[0,*]));-1)+1; [0,2,4]

;         al_legend, box=0, thick=5, color=radii_color, goodtex(string(format='(F4.1)', radii) + ' R_{Earth}'), /top, /right, linestyle=0;subset

  smultiplot
  plot, sensitivity.period.grid, sensitivity.period.detection[*,0], /xstyle, /ystyle, xrange=[0.6,20], xtitle='Period (days)', ytitle=goodtex('MEarth Sensitivity !C!D(effective # of stars searched,!C!Dincluding transit probability!C!D+ per-star sensitivity)'), /ylog, /xlog, yrange=[1, 100], /nodata; title='                      '+label
  loadct, file='~/zkb_colors.tbl',39
xy_sens =  reverse(2*10^(findgen(n_radii)/(n_radii-1.0)*alog10(10)))
  for i=0,n_elements(subset)-1 do begin
    m = subset[i]


    oplot, sensitivity.period.grid, sensitivity.period.detection[*,m], color=radii_color[m], thick=6, linestyle=0;subset[i]
    oplot, sensitivity.period.grid, sensitivity.period.detection[*,m], color=radii_color[m], thick=6, linestyle=0;subset[i]

	slope = smooth((alog10(sensitivity.period.detection[1:*,m])-alog10(sensitivity.period.detection[*,m]))/(alog10(sensitivity.period.grid[1:*]) - alog10(sensitivity.period.grid))*(!p.position[3] - !p.position[1])/(!p.position[2] - !p.position[0])*!d.y_size/!d.x_size*alog10(20/.6)/2, 100)
	angle = atan(interpol(slope,  sensitivity.period.detection[1:*,m], xy_sens[m]))*180/!pi
	xyouts, interpol(sensitivity.period.grid, sensitivity.period.detection[*,m], xy_sens[m]), 0.92*xy_sens[m], color=255, goodtex(string(format='(F3.1)', radii[m]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charthick=40

	xyouts, interpol(sensitivity.period.grid, sensitivity.period.detection[*,m], xy_sens[m]), 0.92*xy_sens[m], color=radii_color[m], goodtex(string(format='(F3.1)', radii[m]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5
	print,  interpol(sensitivity.period.grid, sensitivity.period.detection[*,m], xy_sens[m]), xy_sens[m],  goodtex(string(format='(F3.1)', radii[m]) + ' R_{Earth}')
   endfor
  ;      xyouts, [10.5,7, 5]-2, [9,4,2]+2, goodtex(string(format='(F3.1)', radii[subset]) + ' R_{Earth}'), alignment=0.5, orientation=-45
   
smultiplot
  plot, sensitivity.temp.grid, sensitivity.temp.detection[*,0], /xstyle, /ystyle, xtitle='Equilibrium Temperature (K)!C!D[assuming zero albedo]', /ylog, yrange=[1, 100], xrange=[250,max(sensitivity.temp.grid)], /nodata;, title=label
;axis, yaxis=1, ytitle='Planets / '
  for i=0,n_elements(subset)-1 do begin
    m = subset[i]
 
    oplot, sensitivity.temp.grid, sensitivity.temp.detection[*,m], color=radii_color[m], thick=6, linestyle=0;subset[i]
    oplot, sensitivity.temp.grid, sensitivity.temp.detection[*,m], color=radii_color[m], thick=6, linestyle=0;subset[i]


	slope = smooth((alog10(sensitivity.temp.detection[1:*,m])-alog10(sensitivity.temp.detection[*,m]))/((sensitivity.temp.grid[1:*]) - (sensitivity.temp.grid))*(!p.position[3] - !p.position[1])/(!p.position[2] - !p.position[0])*!d.y_size/!d.x_size*(max(sensitivity.temp.grid)-250)/2., 1)

	angle = atan(interpol(slope,  sensitivity.temp.detection[1:*,m], xy_sens[m]))*180/!pi
	xyouts, interpol(sensitivity.temp.grid, sensitivity.temp.detection[*,m], xy_sens[m]), 0.92*xy_sens[m], color=255, goodtex(string(format='(F3.1)', radii[m]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5, charthick=40

	xyouts, interpol(sensitivity.temp.grid, sensitivity.temp.detection[*,m], xy_sens[m]), 0.92*xy_sens[m], color=radii_color[m], goodtex(string(format='(F3.1)', radii[m]) + ' R_{'+zsymbol(/earth)+'}'), orient=angle, align=0.5
	print,  interpol(sensitivity.temp.grid, sensitivity.temp.detection[*,m], xy_sens[m]), xy_sens[m],  goodtex(string(format='(F3.1)', radii[m]) + ' R_{Earth}')
print, angle

  endfor
 ;   xyouts, [300,350, 400], [8.5,4.5,3], goodtex(string(format='(F3.1)', radii[subset]) + ' R_{Earth}'), alignment=0.5, orientation=50
 


  smultiplot, /def
  device, /close
 epstopdf,label+'sensitivity.eps'

estimate_occurrence, sensitivity_filename=filename
  set_plot, 'x'
  

  
  
END