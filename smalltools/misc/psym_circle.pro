if not keyword_set(circle_size) then circle_size=1.0
theta = findgen(11)/10*2*!pi
usersym, cos(theta)*circle_size, sin(theta)*circle_size, /fill
