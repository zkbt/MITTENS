PRO plot_candidate, candidate, n_lc=n_lc, lc=lc, folder=folder, eps=eps, diagnosis=diagnosis, pdf=pdf
  common this_star
  if not keyword_set(n_lc) then n_lc=1        
  if not keyword_set(folder) then folder=''
  xplot, 11
	cleanplot, /silent
xplot, 11
  plot_lightcurves,n_lc, /phased, /time, candidate=candidate, /fixed, wtitle=star_dir + 'FEPF '+(folder)+' | ' + star_dir, lc=lc, eps=eps, diagnosis=diagnosis, pdf=pdf
 ; print, 'probability of false alarm = ', false_alarm(candidate.chi, /display)
END