; pick a star for Jonathan to stare at
s = load_photometric_summaries(ye=11)
temp = struct_conv({planet_1sigma:s.planet_1sigma, ratio:s.planet_1sigma/s.predicted_planet_1sigma, stellar_radius:s.info.radius, parallax:s.info.parallax})
i = where(s.info.parallax gt 0)
plot_Nd, temp[i]
