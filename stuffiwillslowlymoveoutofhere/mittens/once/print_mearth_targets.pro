s = compile_sample()
i = where(s.radius lt 0.35 and s.d lt 33)
print_struct, s[i], file='mearth_target_stars.txt', form_float=['G', '16', '8']
spawn, 'head mearth_target_stars.txt'