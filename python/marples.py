import numpy as np
from zachopy.Talker import Talker
import matplotlib.pyplot as plt
import astropy.table, astropy.io.ascii
import zachopy.display
#import folder

period_max = 20.0

class Marples(Talker):
    def __init__(self, filename='test_marples.txt'):
        """initialize a Marples object, by reading it from a file"""

        # initialize the talker
        Talker.__init__(self)

        # read in the raw marple text file
        self.read(filename=filename)

        # populate a uniform grid (which will be mostly zeros) with definied marples
        self.gridify()

    def read(self, filename=None):
        """read marples from text file, which must be of format
            time, depth, uncertainty, depth, uncertainty, ... etc
            for different durations."""

        # set the filename for this marple structure
        self.filename = filename
        self.speak('loading text MarPLEs from {0}'.format(filename))

        # load the data
        data = np.loadtxt(filename)

        # define the grid of durations (currently a kludge -- should make this more stable to different formats/ndurations)
        self.ndurations = (data.shape[1]-1)/2
        min_duration, max_duration = 0.02, 0.1
        self.durations = np.linspace(min_duration, max_duration, 9)
        assert(len(self.durations) == self.ndurations)

        # pull out the time stamps, and the depths and uncertainties
        self.hjd = data[:,0]
        self.depths, self.uncertainties = data[:,1::2].transpose(), data[:,2::2].transpose()

        # prune places where uncertainties are negative, implying they are undefined
        bad = self.uncertainties < 0
        self.uncertainties[bad] = np.inf

        # figure out the start and stop of constrained marples
        self.hjd_min = np.min(self.hjd)
        self.hjd_max = np.max(self.hjd)

        # determine which gaps are usual gridpoints (as opposed to nightly gaps)
        gaps = self.hjd[1:] - self.hjd[:-1]
        ok = gaps < 1.5*np.min(gaps)

        # determine the time step between adjacent data points
        self.hjd_step = np.round(np.median(gaps[ok])*24.0*60.0)/24.0/60.0 # rounded to nearest minute (because we assume that's how the grid was created)

        # calculate the indices these timestamps would have in a uniform grid
        self.indices = np.round((self.hjd - self.hjd_min)/self.hjd_step).astype(np.int)

    def gridify(self, tail=20):
        """
        Takes a Marple time series with gaps and creates a "gapless" and evenly spaced array
        Fill in gaps with points that have 0 inverse variance (infinite uncertainties)
        """

        # create an empty dictionary to store everything on a *uniform* grid of times
        self.grid = {}

        # create uniform grid of times that spans the entire duration of the dataset
        self.grid['hjd'] = np.arange(self.hjd_min, self.hjd_max + self.hjd_step + tail, self.hjd_step)

        # how big is the grid?
        self.ngrid = self.grid['hjd'].shape[0]
        self.gridshape = (self.ndurations, self.ngrid)
        # create empty depth and uncertainty grids

        self.grid['depths'] = np.full(self.gridshape, np.nan, dtype=np.float)
        self.grid['uncertainties'] = np.full(self.gridshape, np.inf, dtype=np.float)

        # populate them with data where we have it
        self.grid['depths'][:, self.indices] = self.depths
        self.grid['uncertainties'][:, self.indices] = self.uncertainties

        # calculate the inversevariance over the whole grid
        self.grid['inversevariances'] = 1.0/self.grid['uncertainties']**2

    def plot(self):
        figure = plt.figure('marples', figsize=(10,20), dpi=72)
        figure.clf()
        gs = plt.matplotlib.gridspec.GridSpec(self.ndurations, 1, hspace=0.1, wspace=0, left=0.2)
        share = None
        for i in range(self.ndurations):
            ax = plt.subplot(gs[i], sharex=share, sharey=share)
            if i < (self.ndurations-1):
                plt.setp(ax.get_xticklabels(), visible=False)
            share=ax
            ok = self.grid['inversevariances'][i] > 0
            ax.errorbar(self.grid['hjd'][ok], self.grid['depths'][i,ok], self.grid['uncertainties'][i,ok], alpha=0.8)
            ax.set_ylabel('{0}hr'.format(24*self.durations[i]), rotation=0, ha='right')
        plt.show()



    #def plot(self, period=?, midtransit=?, phasefolded=True/False):

    def fold(self,  type='slow'):
        if type == 'slow':
            return folder.fold(self.grid['hjd'], self.grid['depths'], self.grid['inversevariances'])

    '''    #@numba.jit(nopython=True)
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
            inversevariances = self.grid['inverservariances'][:,intransit + i]



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
                '''
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


if __name__ == '__main__':
    f = Folder()
    f.foldall()
