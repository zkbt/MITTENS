ensemble_priors = load_ensemble_priors()
save, filename=working_dir + 'ensemble_priors.idl', ensemble_priors
ensemble_boxes = load_ensemble_boxes()
save, filename=working_dir + 'ensemble_boxes.idl'
ensemble_nightly_fits = load_ensemble_nightly_fits()
save, filename=working_dir + 'ensemble_nightly_fits.idl'