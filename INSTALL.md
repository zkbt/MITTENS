This document describes how to install the MITTENS, the MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths. It assumes that you are a member of Dave's "exoplanet" group on the CF Unix network. If you're not a member, become a member!


### INSTALLING THE IDL-SQL INTERFACE

To have access to all features (such as being able to ds9 images corresponding to selected data points in the North), you'll need to install the IDL SQL interface that Jonathan put together for MEarth. To do so, follow the instructions Jonathan wrote up in `/data/mearth1/db/CLIENT-SETUP`. They are summarized here:

* create a hidden .postgressql/ directory in your home directory:
`cp /data/mearth1/db/CLIENT-SETUP.tar ~/.`  
`cd ~/`  
`tar -xvf CLIENT-SETUP.tar`  

* open `~/.postgresql` in your favorite text editor and change the "user=" field to your CF account name (this works because Jonathan already created SQL accounts for all of us)

* add the following two lines to your .myrc file:
`setenv IDL_DLM_PATH /data/mearth1/db/idl`  
`setenv PGSERVICE mearth`
(the mittens_setup.sh script will also try to add these lines, so you can exclude them if you will be using the IDL database link solely for MITTENS)

You should now be able to access the SQL database directly from IDL.


### INSTALLING THE MITTENS CODE

For the most part, MITTENS is just big group of IDL *.pro files that can be used for poking around in MEarth data. To use these tools, you need to run the following script. I have it included in my ~/.myrc file, but you could also choose to define it as a separate script to run just when you want to use the MEarth IDL tools. It uses some slightly modified versions of IDL procedures with common names (either things in IDL_ASTRO that I modified when the CF updated to IDL 8 or my own procedures which might coincidentally have the same names as some of yours), so this may be a safer option for not breaking your own code. Anyway, these are the lines I include in my .myrc:

    # ----__--------__--------__--------__--------__--------__--------__------ #
    #                                                                          #
    #  MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths   #
    #                                                                          #
    # ----__--------__--------__--------__--------__--------__--------__------ #


    # set the PATH to the MITTENS routines, which you can set to whereever you want
    setenv MITTENS_PATH ~/MITTENS

    # uncomment this if you don't have a PYTHONPATH already defined elsewhere
    setenv PYTHONPATH

    # run the mittens setup script
    source $MITTENS_PATH/mittens_setup.sh


### INSTALL PYTHON DEPENDENCIES

Make sure you have the following Python dependencies:

* `astropy` (0.4.4), can install with `pip`
* `pg`, can install with `python setup.py install` from MITTENS/include/PyGreSQL-3.8.1


### TESTING THE INSTALLATION
Here are two quick tests of the installation:

* 1) type "mittens" from the UNIX prompt. If the code is available, this should open an IDL prompt and run some setup scripts (if you're running it for the first time, it will create a new set of IDL color tables in your home directory). If it fails or if files keep streaming by, it's broken.

* 2) type "res=pgsql_query('select 1')" from the IDL prompt. If you have everything set up correctly with the IDL SQL interface, this should work.

* 3) type "inspect" from the IDL prompt. This should open the main exploratory tool. Try clicking around -- and please report error messages to zkbt@mit.edu or as issues on the github repository.
