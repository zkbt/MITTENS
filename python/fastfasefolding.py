# -*- coding: utf-8 -*-
"""
Created on Wed Dec  9 10:40:57 2015

@author: Nick Mondrik

Function for fast phase folding of MARPLE'd light curves
"""

import numpy as np
import matplotlib.pyplot as plt

def fold(t,d,inverse_var,P,etft):
    """
    Function to fold Marple lightcurves of d/sigma to a master d/sigma.
    Inputs:
    t    :: Nx1 array of times
    d    :: NxM array of depths for M durations
    sigma:: NxM array of sigmas for M durations
    P    :: Period to fold on
    eft  :: Expected time of first transit #need to change this to an initial phase
    """    
    etft = etft - np.min(t)            
    dt = t[1]-t[0]
    t = t - np.min(t) #move data for easier indexing
    
    #This code can check if the dt's are constant, but we are trusting here...
    #dtp = set(t[1:]-t[:-1])
    #if len(dtp) > 1:
    #    print "Warning: delta_t's not strictly equal!  Inaccuracies could result!"
    
    #number of columns (trial durations) in data
    ncol = d.shape[1]
    dsig_out = []
    dbar_out = []
    carr = []
    tmax = np.max(t)
    nmax = np.ceil(tmax/P)
    n = np.arange(0,nmax,1)
    etts = P*n + etft
    #need to deal with inserted data - maybe something like data_transit = data_transit[data_transit != -99/0/w.e]?
    for m in xrange(ncol):
        #Find centers and pull out data closest to center of presumed transit
        centers = np.rint(etts/dt).astype(np.int)
        centers = centers[centers<d[:,m].size]
        data_transit = d[centers,m]
        ivar_transit = inverse_var[centers,m]
        
        #Cut the data where it has been filled with nan/inf values
        cliparr = np.logical_and(np.isfinite(data_transit), \
                                                   np.isfinite(ivar_transit))
        data_transit = data_transit[cliparr]
        ivar = ivar_transit[cliparr]
        
        dbar = np.sum(data_transit*ivar)/np.sum(ivar)
        sigbar = np.sqrt(1./np.sum(ivar))
        #Compute Chi^2 values for rescaling, if needed (maybe this can be improved?)       
        chisq = np.sum((data_transit - dbar)**2.*ivar)
        #print "CHISQ %5.4f" % chisq
        count = np.sum(ivar>0.)
        #print "COUNT %d" % count
        if chisq <= count or count <= 1:
            rescaling = 1
        else:
            rescaling = np.sqrt(chisq/(count-1.))
        #print "RESCALING %5.4f" % rescaling
        dsig = dbar*np.sqrt(np.sum(ivar))/rescaling
        
        #output values
        carr.append(centers)
        dsig_out.append(dsig)
        dbar_out.append(dbar)
    return np.array(dsig_out)#np.array(carr).T

def main():
    verbose = False
    np.random.seed(7)
    tmin = 0
    tmax = 100
    npoints = 100
    err = 0.2
    test_times = np.linspace(tmin,tmax,npoints)
    test_sigma = np.random.normal(err,0.05,npoints)
    test_data = np.zeros((npoints,9))
    test_sigmas = np.zeros_like(test_data)
    P = 5.7
    
    i = 0
    while i < test_data.shape[1]:
        test_data[:,i] = np.random.normal(0,np.abs(test_sigma),npoints)
        test_sigmas[:,i] = test_sigma
        i += 1
    test_data0 = test_data[:,3]
    
    
    for i,val in enumerate(test_times):
        phase = (val % P)/P
        if phase >= 0.4 and phase <= 0.6:
            test_data[i] += 0.7
        if val > 30 and val < 50:
           test_data[i] = np.nan
           test_sigma[i] = np.inf
    
    if verbose:
        plt.figure(facecolor="white")
        plt.plot(test_times,test_data0,'ko')
        plt.errorbar(test_times,test_data0,yerr=test_sigma,ecolor='k',fmt="none")
        plt.gca().invert_yaxis()
        plt.show() 
        phases = (test_times % P)/P
        plt.plot(phases,test_data0,'ko')
        plt.errorbar(phases,test_data0,yerr=test_sigma,ecolor='k',fmt="none")
        plt.gca().invert_yaxis()
        plt.show()
    #convert sigmas to inverse variances
    test_ivars = 1./(test_sigmas*test_sigmas)
    est,cent = fold(test_times,test_data,test_ivars,P,tmin+0.5*P-tmin%P)
    print est
    
    if verbose:
        plt.plot(test_times,test_data0,'ko')
        nextper = P/2.
        while nextper < 100:
           plt.axvline(nextper,color='k',linestyle='dashed')
           nextper += P
        plt.errorbar(test_times,test_data0,yerr=test_sigma,ecolor='k',fmt="none")
        plt.plot((test_times[cent[:,0]]),test_data0[cent[:,0]],'ro')
        plt.gca().invert_yaxis()
        plt.show()


    
#if __name__ == "__main__":
#    main()
