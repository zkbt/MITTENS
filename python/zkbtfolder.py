from zachopy.Talker import Talker
import numpy as np, matplotlib.pyplot as plt
import zachopy.utils, glob
plt.ion()
#cimport numpy as np

#DTYPE = np.float
#ctypedef np.float_t DTYPE_t


class Folder(Talker):
    def __init__(self, marple, output='untrimmed'):
        Talker.__init__(self)
        self.marple = marple

        self.directory = output + '/'
        zachopy.utils.mkdir(self.directory)

    @property
    def label(self):
        return self.directory + 'spectrum_{0}periods_spanning{1}to{2}'.format(len(self.periods), np.min(self.periods), np.max(self.periods))

    def plotSpectrum(self):
        plt.cla()
        plt.plot(self.periods, np.transpose(self.snr), alpha=0.3)
        plt.xlabel('Period (days)')
        plt.ylabel('D/sigma')
        plt.draw()
        plt.savefig(self.label + '.pdf')

    def save(self):
        np.save(self.label + '.npy', (self.iperiods, self.snr))

    def load(self):
        possibilities = glob.glob(self.directory + 'spectrum_*periods_spanning{1}to{2}.npy'.format(len(self.periods), np.min(self.periods), np.max(self.periods)))
        n = np.array([p.split('/')[-1].split('_')[1].split('periods')[0] for p in possibilities]).astype(np.int)
        filename = possibilities[np.argmax(n)]
        self.iperiods, self.snr = np.load(filename)

    @property
    def periods(self):
        return self.iperiods*self.marple.hjd_step

    def interleave(self):

        delta = (self.iperiods[1:] - self.iperiods[:-1])
        self.new_iperiods = self.iperiods[:-1] + delta/2.0
        self.old_iperiods = self.iperiods

        self.new_snr = self.snr[:,:-1]*0.0
        self.old_snr = self.snr

        self.speak('adding {0} new periods'.format(len(self.new_iperiods)))

        for i in range(len(self.new_iperiods)):
            self.new_snr[:,i] = self.foldby(self.new_iperiods[i])

        self.snr = np.hstack([self.old_snr, self.new_snr])
        self.iperiods  = np.hstack([self.old_iperiods, self.new_iperiods])

        sorted = np.argsort(self.iperiods)
        self.snr = self.snr[:,sorted]
        self.iperiods = self.iperiods[sorted]

        self.plotSpectrum()
        self.save()

    def fold(self, n=10, period_minimum=1.5, period_maximum=1.7, plot=False):
        # fold over a range of periods

        # set up period grid
        periods = np.linspace(period_minimum, period_maximum, n)

        # calculate how many marple grid steps this corresponds to
        self.iperiods = periods/self.marple.hjd_step

        self.nmax = (self.marple.hjd_max - self.marple.hjd_min)/self.marple.hjd_step

        # create an empty SNR array
        self.snr = np.zeros((self.marple.grid['depths'].shape[0], self.periods.shape[0]))

        self.nudge = 0
        self.plot=plot

        # loop over the periods
        for i in range(len(self.periods)):
            print '{0}/{1}'.format(i,n)
            self.snr[:,i] = self.foldby(self.iperiods[i])

    def findbestepoch(self, period):
        iperiod = period/self.marple.hjd_step
        snr = self.foldby(iperiod, dontcollapse=True)
        tobeat = 0
        for id in range(len(self.marple.durations)):
            best = np.nanargmax(snr[id,:])
            print best, snr[id,best]
            if snr[id,best] > tobeat:
                iepoch = best
                tobeat = snr[id,best]
                duration = self.marple.durations[id]
            plt.plot(snr[id,:], alpha=0.3)
            plt.scatter(best,snr[id,best], marker='o')
            plt.draw()
        return self.marple.grid['hjd'][0] + iepoch*self.marple.hjd_step, duration, tobeat


    def foldby(self, iperiod, verbose=False, dontcollapse=False):
        '''fold the marples by a given number of gridpoints'''

        if verbose:
            self.speak('folding to P={0} grid-points'.format(iperiod))

        ncycles = np.floor(self.nmax/iperiod).astype(np.int)
        nepochs = np.ceil(iperiod).astype(np.int)
        ndurations = self.marple.ndurations

        atsamephase = np.round(iperiod*np.arange(ncycles)).astype(np.int)
        atsameepoch = np.arange(nepochs)

        indices = atsamephase.reshape(ncycles, 1) + atsameepoch.reshape(1, nepochs)

        de, iv = self.marple.grid['depths'], self.marple.grid['inversevariances']
        numerator = np.sum(de[:,indices]*iv[:,indices], 1)
        denominator = np.sum(iv[:,indices], 1)


        depth = numerator/denominator
        inversevariance = denominator

        # this step rescales the uncertainties to include the variance of the data itself
        chisq = np.sum((de[:,indices] - depth.reshape(ndurations,1,nepochs))**2*iv[:,indices], 1)
        count = np.sum(iv[:,indices]>0, 1)
        rescaling = np.sqrt(np.maximum(chisq/np.maximum((count - 1),1), 2))

        snr = depth*np.sqrt(inversevariance)/rescaling

        if self.plot:
            plt.plot(np.transpose(snr) + self.nudge, alpha=0.5)
            self.nudge += 3

        if dontcollapse:
            return snr
        return np.nanmax(snr, 1)
