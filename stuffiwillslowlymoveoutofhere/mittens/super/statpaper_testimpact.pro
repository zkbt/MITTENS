PRO statpaper_testimpact, year=year, trigger=trigger
  common this_star
  common mearth_tools
@planet_constants
year = 8
tel = 1
if keyword_set(trigger) then the_dir_with_the_fake = fake_trigger_dir else the_dir_with_the_fake=fake_dir
star_dirs = subset_of_stars(the_dir_with_the_fake+ 'injected_and_recovered.idl',  year=year, tel=tel, lspm=lspm, radius_range=radius_range)

n = 100
for i=0, n -1 do begin
	star_dir = star_dirs[i]
	restore, star_dir + the_dir_with_the_fake +  'injected_and_recovered.idl'
	if n_elements(big_injected) eq 0 then big_injected = injected else big_injected = [big_injected, injected]
	if n_elements(big_recovered) eq 0 then big_recovered = recovered else big_recovered = [big_recovered, recovered]
	print, star_dir
endfor
i_neptunes = where(big_injected.radius eq 4.0)
inj = big_injected[i_neptunes]
rec = big_recovered[i_neptunes]
stellar_radius = inj.radius*r_earth/r_sun/sqrt(inj.depth)
detected = rec.n_sigma gt 7.5
i = where(detected)
wobble = randomn(seed, n_elements(stellar_radius))*0.001
plot, stellar_radius + wobble, inj.b, psym=3
oplot, stellar_radius[i] +wobble[i], inj[i].b, psym=3, color=250 
stop
END