"""
Candidate class
Author: Hannah Diamond-Lowe (hannah.diamond-lowe@cfa.harvard.edu)
Date: 11 Dec. 2015 (MEarth camp!)

This class describes a candidate planet and helps to visualize the likelihood of different transit durations.

"""

from marples import Marples
import matplotlib.pyplot as plt
import matplotlib.gridspec as grd
import numpy as np
from zachopy import cmaps

#test marples period = 1.628930
#test marples mid transit time = 2457184.55786 - 2400000.5

class Candidate():

    def __init__(self, marples_object, period=None, mid_transit_time=None):

        # period in days
        self.period = period

        self.mid_transit_time = mid_transit_time

        # take on marples_object grid - has durations, depths, and depth uncertainties
        self.grid = marples_object.grid

        self.ndurations = marples_object.ndurations
        self.durations = marples_object.durations

    def time_range(self):
        
        # if phasefold=True:
        if self.phasefold:

            phasefold_time = (self.grid['hjd'] - self.mid_transit_time) % self.period
            phasefold_time[phasefold_time > 0.5*self.period] -= self.period

            return phasefold_time

        # if phasefold=False:
        else:

            return self.grid['hjd']

    def plot(self, phasefold=False):
        """
        Here's a fun plotting function!
        Phasefold is default to false, this means that the default is to plot marple depths as a function of the (modified) heliocentric julian date. 
        If you try to plot as a function of phasefolded time without designating a period or mid transit time for the canditate object you will encounter an error.
        """

        self.phasefold=phasefold

        if phasefold:
            if self.period == None:
                print "error: cannot phasefold without a period"
                return
                #return self.grid['hjd']
            elif self.mid_transit_time == None:
                print "error: cannot phasefold without a mid-transit time"   
                return            
                #return self.grid['hjd']

        # establish the error range of whole dataset; this will allow for easier visual comparisons between durations
        ok = self.grid['inversevariances'] > 0
        err_min_comp, err_max_comp = np.percentile(self.grid['inversevariances'][ok], [5, 95])

        # color scheme to use in plotting. using matplotlib color names, like 'red', 'midnightblue', or for some inexplicable reason, 'chartreuse'  http://matplotlib.org/examples/color/named_colors.html may be useful
        color = 'midnightblue'

        for i in range(self.ndurations):

            # set up plot size and grid which will help position subplots
            fig = plt.figure(figsize=(12, 6))
            fig.clf()
            gs = grd.GridSpec(2, 2, width_ratios=[15,1], wspace=0.1, hspace=0.)

            # only use the errors that are not infinite (1/error not equal to 0)
            ok = self.grid['inversevariances'][i] > 0
            #parameters needed for plotting
            time = self.time_range()[ok]     
            depths = self.grid['depths'][i,ok]
            error = self.grid['uncertainties'][i, ok]
            errorplot = self.grid['inversevariances'][i, ok]
            # cut off really good and really bad points, 0.5-0.95 percentile; scale to the overall min and max errors
            errorplot[errorplot < err_min_comp] = err_min_comp
            errorplot[errorplot > err_max_comp] = err_max_comp 
            
            # plot the depths + uncertainties as a function time 
            ax1 = plt.subplot(gs[0])
            # create a transparent color map - one hue
            cmap = cmaps.one2another(color, color, 1., 0.)
            # scatter plot creates the "points" with the color mapped corresponding to the errors
            sc = plt.scatter(time,depths,s=20,marker='None',edgecolor='none',c=errorplot,cmap=cmap)
            # create errorbar plot and return the outputs to a,b,c
            a, b, c = plt.errorbar(time,depths,yerr=error,capsize=0,ls='',zorder=0)
            
            # create a color bar and share it between subplots; colors correspond to the scatter plot color maps
            colorax = plt.subplot(gs[:, -1])
            clb = plt.colorbar(sc, cax=colorax)
            clb.set_label('inverse variance')

            # convert errors to a color tuple using the colormap used for scatter
            error_color = clb.to_rgba(errorplot)
            # adjust the color of c[0], which is a LineCollection, to the colormap
            c[0].set_color(error_color)

            # create a second plot that gives the signal-to-noise for each marple, and also uses the color map!
            ax2 = plt.subplot(gs[2], sharex=ax1)
            ax2.scatter(time,depths/error,marker='.',edgecolor='none',c=errorplot,cmap=cmap)

            # labal stuff on the plot
            ax1.set_ylabel("depths +/- error")
            ax2.set_ylabel("depth/error")
            plt.xlim(time.min(), time.max())
            ax1.set_xlim(time.min(), time.max())
            if phasefold:
                plt.xlabel("phased time")
            else:
                plt.xlabel("hjd time")
            ax1.set_title('transit candidate duration: {0}hr'.format(24*self.durations[i]))

        plt.show()

