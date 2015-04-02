# -*- coding: iso-8859-1 -*-
import os, grp, glob, shutil

exoplanet = grp.getgrnam('exoplanet').gr_gid

mos = glob.glob('mo*/')
for mo in mos:
  for root, dirs, files in os.walk(mo):
    one = [os.path.join(root, name) for name in files]
    os.chown(one, -1, exoplanet)
    os.chmod