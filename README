This README describes the MITTENS', the MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths. It contains information about how to install them, when and how they should be run to keep the processing of incoming data (and modifications to the database) up to date, and how to use them to explore, visualize, and interact with MEarth light curve data.

===============================
BASIC INSTALLATION INSTRUCTIONS
===============================

First, you'll need to install the IDL SQL interface that Jonathan put together for us. To do so, follow the instructions Jonathan wrote up in /data/mearth1/db/CLIENT-SETUP. They are summarized here:

# (1) create a hidden .postgressql/ directory in your home directory
cp /data/mearth1/db/CLIENT-SETUP.tar ~/.
cd ~/
tar -xvf CLIENT-SETUP.tar	

# (2) open ~/.postgresql in your favorite text editor and change the "user=" field to your CF account name (this works because Jonathan already created SQL accounts for all of us)

# add the following two lines to your .myrc file:
setenv IDL_DLM_PATH /data/mearth1/db/idl
setenv PGSERVICE mearth

Now you should be able to access the SQL database directly from IDL.

For the most part, MITTENS is just big group of IDL *.pro files that can be used for poking around in MEarth data. To use these tools, you need to run the following script. I have it included in my ~/.myrc file, but you could also choose to define it as a separate script to run just when you want to use the MEarth IDL tools. It uses some slightly modified versions of IDL procedures with common names (either things in IDL_ASTRO that I modified when the CF updated to IDL 8 or my own procedures which might coincidentally have the same names as some of yours), so this may be a safer option for not breaking your own code. Anyway, put this in your .myrc or into another script file that you run regularly.

# =======================================================================
#  MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths
# =======================================================================
source /home/zberta/idl_routines/zkb/mearth-tools/mittens_setup.sh

Here are two quick tests of the installation:

1) type "mittens" from the UNIX prompt. If the code is available, this should open an IDL prompt and run some setup scripts (if you're running it for the first time, it will create a new set of IDL color tables in your home directory). If it fails or if files keep streaming by, it's broken.
2) type "res=pgsql_query('select 1')" from the IDL prompt. If you have everything set up correctly with the IDL SQL interface, this should work.
3) type "xinspect" from the IDL prompt. This should open the main exploratory tool!

====================================
SCHEDULE FOR RUNNING VARIOUS MITTENS
====================================

These tools will allow you to run the analysis pipeline (takes a long time, and best run inside a VNC window so you don't have to watch it) and explore the data and results with interactive data visualization tools.


The MITTENS pipeline consists of lots of different routines that convert, through a series of cascading steps, Jonathan's MEarth light curve files into MarPLEs and planet candidates, ready for visualizing. These steps are best run more or less on the following schedule:

--------

[weekly]

Whenever new data comes in, MITTENS will need to be run to propagate these data into the MarPLES and to search them for new candidates. All steps except the phased search can be performed in about a day (for five years of data); the phased search will take longer. Here are the commands:

fits_into_lightcurves
; open MEarth FITS curves,
; pull out target stars, 
; save lightcurves (+ more!) into MITTENS directories

lightcurves_into_marples
; process light curves into MarPLES,
; starting in individual star-year-telescope chunks,
; then combining those chunks into star-year chunks and star chunks

marples_into_candidates
; take MarPLEs, in either star-year or star chunks,
; and search all relevant periods, phases, and durations 
; for the best possible periodic planet candidates

--------

[weekly]

Once the raw data have been processed through into MarPLEs and candidates, run the following commands to summarize the results. They will save files that will be read in by xinspect for navigating throughout the sample.

load_summary_of_observations
load_summary_of_marples
load_summary_of_candidates
;load_ensemble_of_marples
;load_ensemble_of_lightcurves

---
[monthly?}
Whenever new measurements enter the database that could affect the stellar parameter estimates, the MITTENS directories will need to have their internal stellar parameter estimates updated. To do so, run from the |mittens| prompt:

load_stellar_properties
; runs an SQL query, save the structure in the MITTEN directory 

repopulate_stars_with_new_parameters
; goes into each star directory, and replaces its stellar parameters
---











KNOWN BUGS

can't select data points when diagnostics are turned on (an annoying problem!)

