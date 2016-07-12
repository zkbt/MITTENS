	raw_censorship_size = 2.0/24.0/60.0
;
	censorship_size = 10.0/24.0/60.0
; how many robust sigma required to be called an outlier
			n_sigma_comparisons = 4.0
; maximum fraction of bright comparisons that can be outliers
			n_outlier_fraction = 0.1
; maximum (negative) delta mag
			extc_limit =  -0.25
; maximum deviation of RMS from median, in robust sigma
			rms_limit =100.0; 0.05;
; maximum deviation of RMS from median, in robust sigma
			sky_limit = 4000.0; 4.0
; maximum deviation of RMS from median, in robust sigma
			peak_limit = 40000.0; 4.0

; maximum pointing error (on each side of the meridian), in "sigma"
			pointing_limit = 5.0
; maximum offset in either x or y direction (in pixels)
xy_limit = 20
; maximum deviation of FLUXERR from median, in robust sigma
			error_limit = 10.0
; maximum astrometric error (defunct?)
			stdcrms_limit = 0.2
; maximum ellipticity
			ellipticity_limit = 0.25
; minimum number of points allowed per week, before being dropped
      weekly_density_limit = 0; 7
; minimum number of points allowed yper week, before being dropped
      daily_density_limit = 0
; min time span per night
      short_night_limit = 0.0;.5/24.0
; direct outlier clipping! be careful! (earth radii)
	radius_limit = 10000.0;6.0
; bandwagon timescale (if more than half the points are bad in this window, throw out all...)
	bandwagon_time = 4.0/24.0
	bandwagon_limit = 0.5
; maximum seeing deviation, in robust sigma
			seeing_limit = 3.0
; minimum number of data points required to go on with search
			min_number_of_points = 50
; time scale over which to filter (potentially) time-varying quantities
			observatory_change_time = 30.0;28.0

; make these more lenient, if keyword set
	if keyword_set(lenient) then begin
		n_outlier_fraction *= 4
		extc_limit *= 4
		rms_limit *= 4
		pointing_limit *=3
		error_limit *= 5
		ellipticity_limit = 0.3
	;	weekly_density_limit=0
	endif

; common mode filtering
	cm_minimum_n = 10; 50
	cm_minimum_n_fields = 10; 25
