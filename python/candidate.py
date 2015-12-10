from marples import Marples
import matplotlib.pyplot as plt
import numpy as np

class Candidate():

    def __init__(self, marples_object, period=1.628930, mid_transit_time=2457184.55786):

        # period in days
        self.period = period

        self.mid_transit_time = mid_transit_time - 2400000.5
        # duration in hours
        #self.duration = duration
        
        # transit depth
        #self.depth = 0.01
    
        # transit depth uncertainty
        #self.depth_unc = 0.001

        # take on marples_object grid - has durations, depths, and depth uncertainties
        self.grid = marples_object.grid

        self.ndurations = marples_object.ndurations
        self.durations = marples_object.durations

        #@property
    def time_range(self):
        
        if self.phasefold:
            
            phasefold_time = (self.grid['hjd'] - self.mid_transit_time) % self.period
            phasefold_time[phasefold_time > 0.5*self.period] -= self.period

            return phasefold_time

        else:

            return self.grid['hjd']

    #def plot(self, period=?, midtransit=?, phasefolded=True/False):

    def plot(self, phasefold=False):

        self.phasefold=phasefold

        figure = plt.figure('marples')#, figsize=(10,20), dpi=36)
        figure.clf()
        gs = plt.matplotlib.gridspec.GridSpec(self.ndurations-8, 1, hspace=0.1, wspace=0, left=0.2)
        share = None

        ok = self.grid['inversevariances'] > 0
        error_compare = self.grid['inversevariances'][ok]
        err_min_comp, err_max_comp = np.percentile(error_compare, [5, 95])
        errorplot_compare = error_compare
        errorplot_compare[errorplot_compare < err_min_comp] = err_min_comp
        errorplot_compare[errorplot_compare > err_max_comp] = err_max_comp

        for i in range(self.ndurations-8):
            ax = plt.subplot(gs[i], sharex=share, sharey=share)
            if i < (self.ndurations-1):
                plt.setp(ax.get_xticklabels(), visible=False)
            share=ax
            ok = self.grid['inversevariances'][i] > 0
            #parameters needed for plotting error bars
            time = self.time_range()[ok]     
            depths = self.grid['depths'][i,ok]
            error = self.grid['uncertainties'][i, ok]
            error_inverse = self.grid['inversevariances'][i, ok]
            
            # cut off really good and really bad points, 0.5-0.95 percentile 
            err_min, err_max = np.percentile(error_inverse, [5, 95])
            errorplot = error_inverse
            errorplot[errorplot < err_min] = err_min_comp
            errorplot[errorplot > err_max] = err_max_comp 

            sc = plt.scatter(time,depths,s=20,edgecolor='none',c=errorplot,cmap=plt.cm.Blues, alpha=.75)
            #sc_compare = plt.scatter(time,depths,s=20,edgecolor='none',c=errorplot,cmap=plt.cm.Blues)

            clb = plt.colorbar(sc)

            #create errorbar plot and return the outputs to a,b,c
            a, b, c = plt.errorbar(time,depths,yerr=error,capsize=0,ls='',zorder=0)

            #convert time to a color tuple using the colormap used for scatter
            error_color = clb.to_rgba(errorplot, alpha=0.75)

            #adjust the color of c[0], which is a LineCollection, to the colormap
            c[0].set_color(error_color)

            fig = plt.gcf()
            #fig.show()

            #ax.errorbar(self.grid['hjd'][ok], self.grid['depths'][i,ok], self.grid['uncertainties'][i,ok], alpha=0.8)
            ax.set_ylabel('{0}hr'.format(24*self.durations[i]), rotation=0, ha='right')
        plt.show()

'''
        ok = self.grid['inversevariances'][0] > 0

        time = self.grid['hjd'][ok]

        
        depths = self.grid['depths'][0,ok]
        error = self.grid['uncertainties'][0, ok]
        error_inverse = self.grid['inversevariances'][0, ok]
        # cut off really good and really bad points        
        err_min, err_max = np.percentile(error_inverse, [5, 95])
        errorplot = error_inverse
        errorplot[errorplot < err_min] = err_min
        errorplot[errorplot > err_max] = err_max


        sc = plt.scatter(time,depths,s=20,edgecolor='none',c=errorplot,cmap=plt.cm.Blues)

        clb = plt.colorbar(sc)

        #create errorbar plot and return the outputs to a,b,c
        a, b, c = plt.errorbar(time,depths,yerr=error,capsize=0,ls='',zorder=0)

        #convert time to a color tuple using the colormap used for scatter
        error_color = clb.to_rgba(errorplot)

        #adjust the color of c[0], which is a LineCollection, to the colormap
        c[0].set_color(error_color)

        fig = plt.gcf()
        fig.show()
'''
