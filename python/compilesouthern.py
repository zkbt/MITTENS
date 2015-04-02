import os
import glob
import astropy.table, astropy.io
import numpy as np
import matplotlib.pyplot as plt

mittens_data = os.getenv('MITTENS_DATA')

print "using Python to concatenate the Southern catalog summary files:"
files = glob.glob('/home/jirwin/mearth/newsouth/summary-*')
print files
bigtable = astropy.table.Table()
tables = []
for f in files:
    print "  loading ", f
    handle = open(f, 'r')
    data = handle.readlines()
    handle.close()
    easytoparse, names = [], []
    for i in range(len(data)):
        easytoparse.append(data[i][:160])
        names.append(data[i][161:].strip())

    table = astropy.io.ascii.read(easytoparse, names=['twomassid', 'rah', 'ram', 'ras', 'decd', 'decm', 'decs', 'epoch', 'pm_ra', 'pm_dec', 'parallax', 'vmag', 'jmag', 'hmag', 'kmag', 'mass', 'radius', 'teff', 'mearthmag', 'mearthexptime', 'exposurespervisit', 'snrrequested', 'snrexpected', 'timepervisit', 'expectedplanetradius', 'numberofreferencestars'])
    table['nameinoriginalcatalog'] = names
    tables.append(table)
    print "       added {0} rows to the catalog".format(len(names))

bigtable = astropy.table.vstack(tables, 'exact')

filename = mittens_data + '/population/compiledsouthernstars.dat'
bigtable.write(filename, format='ascii.fixed_width', delimiter='|', bookend=False)
print "saved compiled southern stars to {0}".format(filename)

