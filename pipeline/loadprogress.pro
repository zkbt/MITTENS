FUNCTION loadprogress

  ; load the progress file for both hemispheres
  readcol, 'population/both_progress.dat', mo, info, filenames, nfilenames, lightcurves, nlightcurves, marples, periodic, delimiter=' ', format='A,D,D,D,D,D,D,D'
  progress = struct_conv({mo:mo, filenames:filenames, info:info, marples:marples, periodic:periodic, lightcurves:lightcurves})
  lag = progress
  for i=1,4 do begin
    lag.(i) = (systime(/sec) - progress.(i))/24.0/60.0/60.0
  endfor
  return, lag

END