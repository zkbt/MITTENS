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

common mearth_tools, display, verbose, done_string, doing_string, skipping_string, tab_string, tf, possible_years, reduced_dir, working_dir, radii, interactive, yearly_filters, fake_dir, fake_trigger_dir, n_effective_for_rescaling, colorbars

; define data directories in which to look for data for each year
possible_years = [2008,2009,2010,2011,2012] ; based on the year in which a season starts (= August/September/October); will need to modify for South
reduced_dir = ['/data/mearth2/2008-2010-iz/reduced/','/data/mearth2/2008-2010-iz/reduced/', '/data/mearth2/2010-2011-I/reduced/', '/data/mearth1/reduced/', '/data/mearth1/reduced/']
yearly_filters = ['iz', 'iz', 'I', 'iz','iz']

; set working directory; on CfA network or on laptop?
;if getenv('HOME') eq '/Users/zachoryberta' then working_dir = '/Users/zachoryberta/mearth/' else 

working_dir = '/pool/eddie1/zberta/mearth_most_recent/'

; set directory for general plots
plot_dir = working_dir + 'plots/'
; fake_dir = 'fake_phased/'
; fake_trigger_dir = 'fake_trigger/'
fake_dir = 'final_fake_phased/'
fake_trigger_dir = 'final_fake_trigger/'

; move to working directory
cd, working_dir

; initialize parameters
;radii = ;[4.0, 3.0, 2.5, 2.2, 2.0;, 1.7, 1.5]
radii = [4.0 ,  3.3 ,     2.7 ,     2.2   ,   1.8    ,  1.5];s = 10^(-findgen(6)*.5);print, s^(1./6.)*4.0

display = 1
verbose = 1
interactive = 0
@mearth_strings
tf = ['false', 'true']
!quiet = 1


; set colorbars for plotting multiple light curves
colorbars = [60,62,54,56,58];42,44,46,52,56,54,58,48]
colorbars = [colorbars, colorbars, colorbars, colorbars]
n_effective_for_rescaling = 4
printl
print, ' now running MEarth IDL Tools for Transits of Extrasolar Neptunes and Super-earths (MITTENS)!'
print, '   working_dir   = ', working_dir
print, '   plotting?     = ', tf[display]
print, '   interactive?     = ', tf[interactive]
print, '   verbose?      = ', tf[verbose]
print, '   !quiet?       = ', tf[!quiet]
printl
print

@psym_circle
!prompt = '|mittens| '
if file_test('ls0*') then set_star, /random
if file_test('ls0*') then temp = star_dir()
;if n_elements(file_search(working_dir + 'ls*/')) gt 100 then set_star, /random, n=50
print