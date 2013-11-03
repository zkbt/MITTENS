PRO plot_superfit, super, eps=eps
  common this_star
 ;plot the SVD weights
;  if keyword_set(display) then begin
;    set_plot, 'x'
;    plot, w, psym=1, ys=3
;    hline, singular_limit
;    xyouts, indgen(n_elements(w)), w, fit[i_include].name, orient=45, charsize=2
;    set_plot, 'ps'
;  endif
;  

  xaxis = indgen(n_elements(super.cleaned))
  filename=star_dir + 'superfit.eps'
  
  if keyword_set(eps) then begin
    set_plot, 'ps'
    device, filename=filename, /encapsulated, /color, /inches, xsize=7.5, ysize=5
    symsize=0.3
  endif else begin
    xplot, 9, xsize=800, ysize=600, title='superfit | ' + star_dir
      cleanplot, /silent
    xplot, 9, xsize=800, ysize=600, title='superfit | ' + star_dir

    symsize=0.5
    
  endelse
  
  loadct, 39, /silent
  scale = 5*1.48*mad(super.lc.flux) < max(abs(super.lc.flux)) < 0.1
  !y.range=[scale, -scale]
  multiplot, /init, [1,3], ygap=0.01
  multiplot
  
  !y.title = 'Uncorrected'
  lc = super.lc
  plot_lc, lc, symsize=symsize, time=time
  loadct, 43, file='~/zkb_colors.tbl', /silent
  
  oplot, xaxis, super.variability+super.decorrelation, color=250

  multiplot
  !y.title = 'Decorrelated'
  lc.flux -= super.decorrelation
  loadct, 54, file='~/zkb_colors.tbl', /silent
  !p.color=150
  plot, xaxis, lc.flux, xstyle=7, ystyle=5, /nodata
  oploterr, xaxis, super.variability, super.variability_uncertainty, 3
  !p.color=0
  plot_lc,lc, psym=8, symsize=symsize, time=time
  loadct, 43, file='~/zkb_colors.tbl', /silent
  
  oplot, xaxis, super.variability, color=250
 
 
  multiplot
  !y.title = 'sans Variability'
  lc.flux -= super.variability
  loadct, 54, file='~/zkb_colors.tbl', /silent
  !p.color=150

  plot, xaxis, lc.flux, xstyle=7, ystyle=5, /nodata
  oploterr, xaxis, fltarr(n_elements(super.variability)), super.variability_uncertainty,3
  !p.color = 0
  !x.title = 'Observation #'
  plot_lc,lc, psym=8, symsize=symsize, time=time
  multiplot, /def

  if keyword_set(display) then cleanplot, /silent

;  dpi=72
;  spawn, "convert -density "+ strcompress(dpi, /remove_all) + "  " + star_dir + "uberdecorrelation.eps " + star_dir + "uberdecorrelation.png&", result, error
    !y.title = ''
  ; plot, unless told not to
;  if not keyword_set(no_plot) then begin
;    tags = i_include;[0:M-1]
;    tags = tags[reverse(sort(abs(coef)))]
;    tags = tags[where(strmatch(fit[tags].name, 'NIGHT*') eq 0)]
;
;    device, filename=star_dir + 'decorrelation.eps', /inches, /encapsulated, xsize=7.5, ysize=n_elements(tags)+3
;    scale = 5*1.48*mad(lc.flux) < max(abs(lc.flux)) < 0.1
; 
;    !p.thick=1
;    !p.charsize=1
;    !p.charthick=1
;    !y.range = [scale, -scale]
; 	xplot, 21
;    plot_struct, create_struct('RAW', lc.flux, 'DECORRELATED', lc.flux - super.decorrelation,'SANS_VARIABILITY', super.cleaned, templates), tags=[0,1,2,tags+3], ystyle=7, xstyle=5
;    !y.range = [0,0]
;    device, /close
;        spawn, "convert -density "+ strcompress(dpi, /remove_all) + " " + star_dir + "decorrelation.eps " + star_dir + "decorrelation.png&", result, error
; ; endif
  if keyword_set(eps) then begin
    device, /close
   ; epstopdf, filename
  endif
  END
