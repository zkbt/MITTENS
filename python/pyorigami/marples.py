import numpy as np
import pyximport; pyximport.install(setup_args={
                              "include_dirs":np.get_include()},
                  reload_support=True)

from zachopy.Talker import Talker
import matplotlib.pyplot as plt
import astropy.table, astropy.io.ascii
import zachopy.display
import origami

class Folder(Talker):
    def __init__(self, filename='/Users/zkbt/Desktop/mo00113182+5908400_marples.txt'):

        Talker.__init__(self)
        self.period_max = 20.0
        self.read(filename=filename)
        self.gridify()

    def read(self, filename=None):
        self.filename = filename
        self.speak('loading text MarPLEs from {0}'.format(filename))
        data = np.loadtxt(filename)
        self.ndurations = (data.shape[1]-1)/2
        min_duration, max_duration = 0.02, 0.1
        durations = np.linspace(min_duration, max_duration, 9)
        assert(len(durations) == self.ndurations)

        self.hjd = data[:,0]
        depths, uncertainties = data[:,1::2].transpose(), data[:,2::2].transpose()
        self.depths = np.ma.MaskedArray(data=depths, mask=uncertainties <= 0)
        self.uncertainties = np.ma.MaskedArray(data=uncertainties, mask=uncertainties <= 0)

        self.hjd_min = np.min(self.hjd)
        self.hjd_max = np.max(self.hjd)

        # determine which gaps are usual gridpoints (as opposed to nightly gaps)
        gaps = self.hjd[1:] - self.hjd[:-1]
        ok = gaps < 1.5*np.min(gaps)
        self.hjd_step = np.round(np.median(gaps[ok])*24.0*60.0)/24.0/60.0 # rounded to nearest minute
        self.indices = np.round((self.hjd - self.hjd_min)/self.hjd_step).astype(np.int)

    def gridify(self):
        self.grid, self.regridded = {}, {}
        self.grid['hjd'] = np.arange(self.hjd_min, self.hjd_max + self.period_max, self.hjd_step)
        self.ngrid = self.grid['hjd'].shape[0]
        self.grid['depths'] = np.ma.MaskedArray(data=np.zeros((self.ndurations, self.ngrid)), mask=np.ones((self.ndurations, self.ngrid)).astype(np.bool), fill_value=0)
        self.grid['depths'][:, self.indices] = self.depths

        self.grid['uncertainties'] = np.ma.MaskedArray(data=np.zeros((self.ndurations, self.ngrid)), mask=np.ones((self.ndurations, self.ngrid)).astype(np.bool), fill_value=-1)
        self.grid['uncertainties'][:, self.indices] = self.uncertainties

        #self.grid['depths'][0,:] = self.grid['hjd']
        #self.grid['uncertainties'][0,:] = np.ones_like(self.grid['hjd'])
        self.grid['inversevariances'] = 1.0/self.grid['uncertainties']**2

    #@numba.jit(nopython=True)
    def fold(self, period):

        # how many epochs exist for this period?
        nepochs = period/self.hjd_step

        # what is this as an integer?
        integerepochs = np.int(np.ceil(nepochs))

        # wha
        np.int(np.round(np.arange((self.hjd_max - self.hjd_min)/period)*nepochs))
        intransit = (np.round(self.indices/nepochs) == 0).nonzero()

        depths, inversevariances = 0
        for i in range(integerepochs.shape[0]):
            for j in range(intransit.shape[0]):

            depths = self.grid['depths'][:,intransit+i]
            inversevariances = self.grid['inverservariances'][:.intransit + i]



                # regrid the depths and inversevariances, so they're folded back on one another
                regridded_depths = grid_depths[:,0:ntotal].reshape((ndurations, ncycles, nperiod))
                regridded_inversevariances = grid_inversevariances[:,0:ntotal].reshape((ndurations, ncycles, nperiod))

                # stack each period to measure the S/N at all epochs
                cycleaxis = 1
                eweights = np.sum(regridded_inversevariances, cycleaxis)


                epochs_depths = np.sum(regridded_depths*regridded_inversevariances, cycleaxis)/eweights
                epochs_uncertainties = np.sqrt(1.0/eweights)
                epochs_nboxes = np.sum(regridded_inversevariances > 0)

                epochs_chisq = np.sum((regridded_depths - epochs_depths.reshape((ndurations, 1, nperiod)))*regridded_inversevariances)
                epochs_rescaling = np.sqrt(np.maximum(epochs_chisq/(epochs_nboxes-1), 1))
                epochs_uncertainties *= epochs_rescaling

    def foldall(self):
        origami.foldall(self)

    def plotfolding(self):
        try:
            self.ax1d
        except:
            self.fig = plt.figure(figsize=(5,5))
            self.gs = plt.matplotlib.gridspec.GridSpec(2,1,height_ratios=[1,4], hspace=0)
            self.ax1d = plt.subplot(self.gs[0])
            self.ax2d = plt.subplot(self.gs[1])
        self.plotted1d = self.ax1d.plot((self.epochs['depths']/self.epochs['uncertainties']).transpose())

        self.plotted2d = self.ax2d.imshow((self.regridded['depths']/self.regridded['uncertainties'])[0,:,:], interpolation='nearest', cmap='gray', aspect='auto')


    def plot(self, i):
        plt.errorbar(self.hjd, self.depths[i,:], self.uncertainties[i,:], alpha=0.5)
        ok = self.grid_depths[i,:].mask == False
        plt.errorbar(self.grid_hjd[ok], self.grid_depths[i,ok], self.grid_uncertainties[i,ok], alpha=0.5)

if __name__ == '__main__':
    f = Folder()
    f.foldall()
