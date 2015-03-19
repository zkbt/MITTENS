#!/usr/bin/tcsh
#
# =======================================================================
#  MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths
# =======================================================================

# modify the Python path to include the MITTENS python directory (packages within this directory should also be available
setenv PYTHONPATH ${PYTHONPATH}:{$MITTENS_PATH}/python

# sets the directory where are all data (reprocessed LC's, search results, etc...) will be stored
setenv MITTENS_DATA /data/mearth2/marples/

# add the MITTENS code directories to the IDL path
setenv IDL_PATH +{$MITTENS_PATH}:{$IDL_PATH}

# define an alias, so you can type "mittens" from the UNIX prompt
#  (the shell business and umask is an attempt to make sure any changes you make will be group readable/editable)
alias mittens "setenv SHELL /bin/sh; umask 0007; idl mearth.pro"

# the next two lines are needed to allow IDL to access the database
setenv IDL_DLM_PATH /data/mearth1/db/idl
setenv PGSERVICE mearth

# =======================================================================
