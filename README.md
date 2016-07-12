This README describes the MITTENS', the MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths. It contains information about how to install them, when and how they should be run to keep the processing of incoming data (and modifications to the database) up to date, and how to use them to explore, visualize, and interact with MEarth light curve data.

### BASIC INSTALLATION INSTRUCTIONS

Read the [INSTALL.md](https://github.com/zkbt/MITTENS/blob/master/INSTALL.md) document in the main MITTENS directory. There are a few options about how you can have things set up, but it is *essential* that `mittens_setup.sh` is run from your shell before you open the IDL tools. This can be done either by something like `source mittens_setup.sh` from the MITTENS directory or by including something similar in your `.myrc` file.

### STARTING MITTENS

Because you will have run `mittens_setup.sh` above, you can simply type `mittens` from the UNIX prompt. This opens an IDL session, runs a script (`setup/mearth.pro`) to define a bunch of common variables and load some data tables, and points mittens at a random star.

### USING MITTENS TO EXPLORE

Read the [cheatsheet](https://github.com/zkbt/MITTENS/blob/master/cheatsheet.md) of MITTENS commands. The most basic way to explore the dataset is to type `inspect` to open the population of MarPLE-analyzed MEarth data in a data visualization window or `inspect, "GJ 1214"` to focus that inspector on a particular star.

From there, a main population-level window will open. Use the inspector to [going roughly left to right across the window] (1) select a star you're interested in, (2) select a periodic candidate or interesting single event you're interested in, (3) display plots, either individual events, or phased to period, or several other options.

Most of the individual-level plot windows include lots of options for what points or curves to plot [along the left], what time range to focus on [along the bottom], how to output the plot or the star's data [top left], and how to comment on the star [top right]. Comments will be saved as flat text files, in the stars' MITTENS directories. Currently, a few keywords can be used to filter objects in the population plots. If a star's comment file contains:
  * `known`: points from this star can be excluded with the 'known' flag (meant to hide or highlight things we already know about)  
  * `ignore`: points from this star can be excluded with the 'weirdos' flag (meant for hiding stars that have mysteriously bad data; things like shutter failures or blends)  
  * `variability` or `variable` or anything starting with `varib`: points from this star can be excluded with the 'variability' flag (meant to hide stars that are just too darn difficult -- use sparingly!)


### SCHEDULE FOR UPDATING ANALYSES

These tools will allow you to run the analysis pipeline (takes a long time, and best run inside a VNC window so you don't have to watch it) and explore the data and results with interactive data visualization tools.

The MITTENS pipeline consists of lots of different routines that convert, through a series of cascading steps, Jonathan's MEarth light curve files into MarPLEs and planet candidates, ready for visualizing. These steps are best run more or less on the following schedule:

*[weekly-monthly]* Whenever new data comes in, MITTENS will need to be run to propagate these data into the MarPLES and to search them for new candidates. All steps except the phased search can be performed in about a day (for five years of data); the phased search will take longer. Here are the commands:

    fits_into_lightcurves
    ; open MEarth FITS curves, pull out target stars, save lightcurves (+ more!) into MITTENS directories

    lightcurves_into_marples
    ; process light curves into MarPLES, starting in individual star-year-telescope chunks, then combining those chunks into star-year chunks and star chunks

    outsource_folding
    ; upload all the (newly updated) processed MarPLES to the MIT antares cluster for phase-folding (currently, this can still be done only by Zach)

    (run create_scripts.py and submit_batch.py on the antares cluster)
    ; it takes a couple of days for the MIT cluster to crunch through all the phase-fold searches, and the results will be saved in the "results" directory over there

    import_folding
    ; download processed period spectra from the MIT cluster, and move them into the appropriate directories

    origami_into_candidates
    ; process the period spectra to identify interesting peaks (including a soft constraint on transit durations, based on the assume stellar parameters for each target) and save those period candidates

--------

*[weekly-monthly]* Once the raw data have been processed through into MarPLEs and candidates, run the following commands to summarize the results. They will save files that will be read in by inspect for navigating throughout the sample:

    load_summary_of_observations
    load_summary_of_marples
    load_summary_of_candidates
    load_summary_of_comments

*[monthly-yearly]* Whenever new measurements enter the database that could affect the stellar parameter estimates, the MITTENS directories will need to have their internal stellar parameter estimates updated. To do so, run:

    load_stellar_properties
    ; runs an SQL query, saves the structure in the MITTEN directory, repopulates star directories

*[monthly-yearly]* Whenever new measurements enter the database that could affect the stellar parameter estimates, the MITTENS directories will need to have their internal stellar parameter estimates updated. To do so, run:

    load_stellar_properties
    ; runs an SQL query, saves the structure in the MITTEN directory, repopulates star directories

*[when you're curious about a star]* To ingest and process new data on a particular star, you can use:

    update, 'PROXIMA CEN'
    ; this will run `fits_into_lightcurves` and `lightcurves_into_marples` on "PROXIMA CEN"

    update, 'mo09125959-8311515'
    ; this is the same as the above command, but it is generally safer to use
    the MEarth Object identifier ("mo{2MASS numeric string}" or simply "{2MASS
    numeric string}"). The name-matching relies on the top name hit that was
    scrubbed out of Jonathan's database, so isn't always intuitive (e.g.
    `update, 'GJ 1214'` works, but `update, 'LHS 281'` is required to grab GJ1132)

    update, 'mo09125959-8311515', /remake
    ; update up through the marples, even if recent data have already been processed

    update, 'mo09125959-8311515', /origami
    ; run `fits_into_lightcurves`, `lightcurves_into_marples`, `marples_into_origami`, `origami_into_candidates` on this particular star.
    The phase-folding will take quite a while, but this will go all the way to
    candidates for the particular star.

    update, /all
    ; this will run `update` on all the stars, looping through the list of MEarth Objects

### REPORTING BUGS
There *will* definitely be problems with MITTENS.  Please copy error messages to zkbt@mit.edu or [post them as issues](https://github.com/zkbt/MITTENS/issues).

For immediate fixes, running `retall` from the IDL prompt may clear up a temporary problem and get the GUI rerunning. The old close-and-reopen trick has also been found to be successful.
