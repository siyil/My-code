# -*- coding: utf-8 -*-
"""
@siyi.luo
Last updated: 9/20/2019
"""

import numpy as np
from scipy import stats
import matplotlib.pyplot as plt 

nx = 1000
ny = 1000
muxall = list(np.arange(3.0,4.0,0.1))

sigmaall = [0.1,0.15,0.2,0.5]
deltaall = [0.1,0.2,0.3,0.5]

fig, ax = plt.subplots(len(sigmaall), len(deltaall), sharex='col', sharey='row')

for j in range(len(sigmaall)):
    sigma = sigmaall[j]
    for k in range(len(deltaall)):
        delta = deltaall[k]
        cilower = [0]*len(muxall)
        ciupper = [0]*len(muxall)
        
        tcrt = stats.t.interval(0.99,nx+ny-2)[1]
        
        for i in range(len(muxall)):
            mux = muxall[i]
            muy = mux+delta
            np.random.seed(123 + i + 10*j + 100*k)
            X = np.random.normal(mux, sigma, nx)
            np.random.seed(321 + i + 10*j + 100*k)
            Y = np.random.normal(muy, sigma, ny)
                
            xx = np.floor(X)
            yy = np.floor(Y)
                
            dd = np.mean(yy) - np.mean(xx)
            sdx = np.std(xx)
            sdy = np.std(yy)
                
            se = np.sqrt((sdx**2*(nx-1) + sdy**2*(ny-1))/(nx+ny-2))
            
            
            cilower[i] = dd - se*tcrt*np.sqrt(1/nx+1/ny)
            ciupper[i] = dd + se*tcrt*np.sqrt(1/nx+1/ny)
    
            
        ax[j,k].plot(muxall,cilower)
        ax[j,k].plot(muxall,ciupper)
        ax[j,k].plot(muxall,[delta]*len(muxall))
        if k == 0:
            ax[j,k].set_ylabel('sd = '+ str(sigma), rotation=90, size='large')
        if j == 0:
            ax[j,k].set_title('d = ' + str(delta))
            

fig.text(0.5, 0.04, 'mu_x', ha='center', va='center')
fig.text(0.5, 0.96, '99% CI for d', ha='center', va='center')
            
plt.show()

