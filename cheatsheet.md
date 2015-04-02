# MITTENS commands

### run the MarPLE analysis on one star
If you want to update the MarPLES and and the phased periodic candidates for a star, simply run  
    update, name
where `name` can be an LSPM number (1186), a MEarth-Object identifier ('mo17151894+0457496', either with or without the 'mo'), or Jonathan's bestname for the star ('GJ 1214'). If new data is present, running this from start to finish may be a pain, because the phased search takes a very long time. You can run it piecemeal, if you like, using the same steps that `update` uses:

    ; select a specific object
    mo = 'GJ 1214' 
    ; convert Jonathan's FITs lightcurves into IDL structures
    fits_into_lightcurves, mo
    ; convert those lightcurves into MarPLES (transit depths + uncertainties, over a grid of possible transit centers)
    lightcurves_into_marples, mo
    ; convert those MarPLEs into origami spectra (maximum transit S/N over a big grid of periods)
    marples_into_origami, mo
    ; convert those origami spectra into periodic candidates (including estimates of the stellar density to limit durations

### run MarPLE analysis on all stars
Periodically, we should run MITTENS through all the available data and update all the calculations. The steps to do so are basically identical to above, but 
If you want to process all


### navigation
`set_star, [lspm #] or [mo string] or [other name]`

point the MITTENS tools at a star, for plotting or analysis

### miscellaneous tools
`mearth`

convert any IDL session into a MITTENS one, turning on common variables needed for analyzing MEarth lightcurves

`permit`

fix permissions on all files in the marples directory
