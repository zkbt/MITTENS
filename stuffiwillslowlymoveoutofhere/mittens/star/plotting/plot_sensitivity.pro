PRO plot_sensitivity, gauss=gauss, eps=eps
  common this_star
  common mearth_tools
if keyword_set(gauss) then filename = 'gauss_sensitivity.idl' else filename = 'sensitivity.idl'

  if file_test(star_dir + 'injection_test/' + filename) eq 0 then begin
    mprint, skipping_string, "can't plot sensitivity for ",star_dir + 'injection_test/' + filename
    return
  endif
  restore, star_dir + 'injection_test/' + filename
  
  xplot, 16, title=star_dir + ' | detection sensitivity'
  loadct, 39, /silent
  if keyword_set(eps) then begin
     set_plot, 'ps'
    filename = star_dir + 'plots/detection_probability.eps'
    file_mkdir, star_dir + 'plots'
    device, filename=filename, /encapsulated, /color, /inches, xsize=4, ysize=4
    symsize=0.5
    !p.charsize=1.5
    !x.thick=4
    !y.thick=4
    !p.charthick=4
    !P.thick=4
  endif
  n_radii = n_elements(radii)
  loadct, 0
    radii_color =  (1+indgen(n_radii))*180.0/n_radii  
  if not keyword_set(eps) then title=goodtex('threshold = \Delta\chi^2 > ' + strcompress(/remo, string(format='(F6.1)', deltachi))) else title=''
  plot, xrange=[0.6,20], /xlog, periods, sensitivity[*,0]*100, yrange=[0, 1]*100, ys=3, xs=1, /nodata, title=title, xtitle='Period (days)', ytitle='Detection Probability (%)'
 ; al_legend, box=0, 'R=' + string(format='(F3.1)', radii), linestyle=0, color=radii_color, /top, /right
 subset = [0,2,4]
 for i=0,n_elements(subset)-1 do begin
    m = subset[i]    
    oplot, periods, sensitivity[*,m]*100, color=radii_color[m]
  endfor
  if keyword_set(eps) then begin
    device, /close
    epstopdf, filename
    endif
    if not keyword_set(eps) then return
    
      if keyword_set(eps) then begin
     set_plot, 'ps'
    filename = star_dir + 'plots/transit_probability.eps'
    file_mkdir, star_dir + 'plots'
    device, filename=filename, /encapsulated, /color, /inches, xsize=4, ysize=4
    symsize=0.5
    !p.charsize=1.5
    !x.thick=4
    !y.thick=4
    !p.charthick=4
    !P.thick=4
  endif

  plot, xrange=[0.6,20], /xlog, periods, 1.0/a_over_rs(lspm_info.mass, lspm_info.radius, periods)*100, yrange=[0, 1]*100, ys=3, xs=1, xtitle='Period (days)', ytitle='Transit Probability (%)'

    if keyword_set(eps) then begin
    device, /close
    epstopdf, filename
  endif
    
END

