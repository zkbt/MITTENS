PRO characterize_lightcurve

  ; tally the photometric performance of the filtering
    photometry = replicate({stddev:0.0, robust:0.0, type:''}, 3)
    photometry.type = ['target','decorrelated','medianed']
    photometry.stddev = [stddev(target_lc.flux), stddev(decorrelated_lc.flux), stddev(medianed_lc.flux)]
    photometry.robust = [1.48*mad(target_lc.flux), 1.48*mad(decorrelated_lc.flux), 1.48*mad(medianed_lc.flux)]
    save, filename=star_dir +  'photometry.idl', photometry

    ; output text version of photometric performance to be included on star page
    openw, f, star_dir+'robust_noise.txt', /get_lun
    printf, f, '<b>1.48xMAD(*):</b>'
    printf, f, '&nbsp original: ', string(format='(F6.4)', 1.48*mad(target_lc.flux))
    printf, f, '&nbsp decorrelated: ', string(format='(F6.4)', 1.48*mad(decorrelated_lc.flux))
    printf, f, '&nbsp medianed: ', string(format='(F6.4)', 1.48*mad(medianed_lc.flux))
    printf, f, '&nbsp predicted: ', string(format='(F6.4)', median(target_lc.fluxerr))
    printf, f, ''
    close, f
    free_lun, f
    openw, f, star_dir+'noise.txt', /get_lun
    printf, f, '<b>stddev(*):</b>'
    printf, f, '&nbsp original: ', string(format='(F6.4)', stddev(target_lc[i_ok].flux))
    printf, f, '&nbsp decorrelated: ', string(format='(F6.4)', stddev(decorrelated_lc[i_ok].flux))
    printf, f, '&nbsp medianed: ', string(format='(F6.4)', stddev(medianed_lc[i_ok].flux))
    printf, f, '&nbsp predicted: ', string(format='(F6.4)', median(target_lc[i_ok].fluxerr))
    printf, f, ''
    printf, f, ''
    close, f
    free_lun, f

  ; estimate the red noise in the light curve
  estimate_red_noise
END