#!/usr/bin/tcsh
#
# =======================================================================
#  MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths
# =======================================================================

# sets the directory where are all data (reprocessed LC's, search results, etc...) will be stored
setenv MITTENS_DATA /data/mearth2/marples/
# a temporary kludge
setenv IDLUTILS_DIR /home/zberta/idl_routines/sdss
setenv IDL_PATH +/home/zberta/idl_routines:+$IDLUTILS_DIR/pro:+$IDLUTILS_DIR/goddard/pro:{$IDL_PATH}

# set the PATH to the MITTENS routines, and add it to the IDL PATH
setenv MITTENS_PATH ~/idl_routines/zkb/mearth-tools
setenv IDL_PATH +{$MITTENS_PATH}:{$IDL_PATH}

# define an alias, so you can type "mittens" from the UNIX prompt
alias mittens "umask 0007; idl mearth.pro"

# the next two lines are needed to allow IDL to access the database
setenv IDL_DLM_PATH /data/mearth1/db/idl
setenv PGSERVICE mearth

# =======================================================================
