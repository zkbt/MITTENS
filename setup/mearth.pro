;+
; sets up IDL to run in MITTENS (MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths!) mode.
;  
;
; :description:
; :examples:
;
;  1) run "@mearth" from within IDL ::
;  2) run "idl mearth.pro" from UNIX shell :: 
;  3) define a shortcut in ~/.myrc file ('alias mittens "idl mearth.pro"') ::
;
; :categories: 
; :params: none
; :returns: an IDL prompt ready for playing with MEarth data
; :uses: star_dir()
; :author: Zachory K. Berta-Thompson (zkbt@mit.edu)
; :history: Written by ZKBT, sometime while he was in grad school (2008-2013).
;
;-

common mearth_tools, display, verbose, done_string, doing_string, skipping_string, error_string, tab_string, tf, possible_years, reduced_dir, working_dir, radii, interactive, yearly_filters, fake_dir, fake_trigger_dir, n_effective_for_rescaling, colorbars, mo_ensemble, username, typical_candidate_filename, fits_suffix, mo_prefix, mo_regex, observatories, procedure_prefix

procedure_prefix = '[setup]'
; set up the structure of MEarth Objects, which will set their directory structure
mo_prefix = 'mo'
mo_regex = '[0-9]+[+-][0-9]+'


; define data directories in which to look for data for each year
possible_years = [2008,2010,2013, 2013] ; based on the year in which a season starts (= August/September/October); will need to modify for South
reduced_dir = ['/data/mearth2/2008-2010-iz/reduced/','/data/mearth2/2010-2011-I/reduced/', '/data/mearth1/reduced/',  '/data/mearth2/south/reduced/']
observatories = ['N','N','N','S']
yearly_filters = ['iz', 'I', 'iz',  'iz']
fits_suffix = '_daily.fits'

; set working directory; on CfA network or on laptop?
;if getenv('HOME') eq '/Users/zachoryberta' then working_dir = '/Users/zachoryberta/mearth/' else 

; set up directory structure; assumes a $MEARTH_DATA environment variable has been set
working_dir = getenv('MITTENS_DATA');'/pool/eddie1/zberta/mearth_most_recent/'
;file_mkdir, working_dir
file_mkdir, working_dir + 'nights'
file_mkdir, working_dir + 'population'
file_mkdir, working_dir + 'observatory_N'
file_mkdir, working_dir + 'observatory_S'
plot_dir = working_dir + 'plots/'

; fake_dir = 'fake_phased/'
; fake_trigger_dir = 'fake_trigger/'
fake_dir = 'final_fake_phased/'
fake_trigger_dir = 'final_fake_trigger/'

typical_candidate_filename = 'phased_candidates.idl'
; move to working directory
cd, working_dir

if file_test('population/mo_ensemble.idl') eq 0 then load_stellar_properties
if n_elements(mo_ensemble) eq 0 then restore, 'population/mo_ensemble.idl'

; initialize parameters
;radii = ;[4.0, 3.0, 2.5, 2.2, 2.0;, 1.7, 1.5]
radii = [4.0 ,  3.3 ,     2.7 ,     2.2   ,   1.8    ,  1.5];s = 10^(-findgen(6)*.5);print, procedure_prefix,  s^(1./6.)*4.0

display = 1
verbose = 1
interactive = 0
@mearth_strings
tf = ['false', 'true']
!quiet = 1

username = getenv('USER')

; create new colorbar file, if need be
if file_test('~/zkb_colors.tbl') eq 0 then print, procedure_prefix,  "MITTENS require Zach's custom color tables; making them now (this should only happen once)"
if file_test('~/zkb_colors.tbl') eq 0 then make_ct

; set colorbars for plotting multiple light curves
colorbars = [60,62,54,56,58];42,44,46,52,56,54,58,48]
colorbars = [colorbars, colorbars, colorbars, colorbars]
colorbars = [colorbars, colorbars]
n_effective_for_rescaling = 4
printl
print, procedure_prefix,  ' now running MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths (MITTENS)!'
print, procedure_prefix,  '   working_dir   = ', working_dir
print, procedure_prefix,  '   username      = ', username
print, procedure_prefix,  '   plotting?     = ', tf[display]
print, procedure_prefix,  '   interactive?  = ', tf[interactive]
print, procedure_prefix,  '   verbose?      = ', tf[verbose]
;print, procedure_prefix,  '   !quiet?       = ', tf[!quiet]
printl
print



;mittens_permissions

@psym_circle
!prompt = '|mittens| '
if file_test(mo_prefix+'*') then set_star, /random
if file_test(mo_prefix+'*') then temp = star_dir()
print