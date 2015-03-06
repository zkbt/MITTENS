select count(night) from frame where night > 20080801 and night < 20090801;
select count(night) from frame where night > 20090801 and night < 20100801;
select count(night) from frame where night > 20100801 and night < 20110801;
select count(night) from frame where night > 20110801 and night < 20120801;

raw number of frames gathered
305235
379321
517230
510081
=====
1.71187e+06

select count(night) from observation where night > 20080801 and night < 20090801;
select count(night) from observation where night > 20090801 and night < 20100801;
select count(night) from observation where night > 20100801 and night < 20110801;
select count(night) from observation where night > 20110801 and night < 20120801;

305235
309712
303420
254989
=====
1.17336e+06

datapoints that make it into "cleaned_lc"
 b = load_good_binned() 
** Structure <9077d58>, 4 tags, length=146306160, data length=128888760, refs=1:
   YE08            STRUCT    -> <Anonymous> Array[244876]
   YE09            STRUCT    -> <Anonymous> Array[224202]
   YE10            STRUCT    -> <Anonymous> Array[207829]
   YE11            STRUCT    -> <Anonymous> Array[193963]
=====
870870


restore, '2008_obs_summary.idl'
o08 = obs_summary
restore, '2009_obs_summary.idl'
o09= obs_summary
restore, '2010_obs_summary.idl'
o10= obs_summary
restore, '2011_obs_summary.idl'
o11= obs_summary

o = [o08, o09, o10, o11]

  	ls_string = 'ls'+string(format='(I04)', o.lspm)
		ye_string = 'ye' + string(format='(I02)', o.year mod 2000)
		te_string = 'te' + string(format='(I02)', o.tel)

		sd = ls_string + '/' + ye_string + '/' + te_string + '/'

	plot, o.ra, o.dec, /nodata, ys=3, xs=3
	for i=0, n_elements(o)-1 do plots, o[i].ra, o[i].dec, psym=8, symsize=sqrt(o[i].n_goodpointings*5./max(o.n_goodpointings))

for j=0, n_elements(o)-1 do if o[j].n_goodpointings gt 50 and  file_test(sd[j] + 'final_fake_phased/injected_and_recovered.idl') eq 0 then print, sd[j], o[j].n_goodpointings, file_test(sd[j] + 'final_fake_phased/injected_and_recovered.idl')


c = compile_sensitivity(7.5)
for i=0, n_elements(o08)-1 do if total(s.lspm eq o08[i].lspm) eq 0 then print, o08[i].lspm , o08[i].n_goodpointings     




i = where(o.n_goodpointings gt 100 and o.lspm ne 1186 and o.lspm ne 3229 and o.lspm ne 1803 and o.lspm ne 3512)
print, total(o[i].n_goodexposures), total(o[i].n_goodpointings)
;  1.24745e+06      825969.

for j=8,11 do print, n_elements(where(o[i].year eq j)), j
;         349       8
;         306       9
;         256      10
;         240      11


h = histogram(o[i].lspm)  
plothist, h[where(h gt 0)] 

lspm = o[i].lspm
lspm = lspm[sort(lspm)]
u = uniq(lspm)
lspm = lspm[u]
info = get_lspm_info(lspm)
help, info


 b = load_good_binned()   
i = 
