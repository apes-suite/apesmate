## This is the user-script for plotting using gleaner tool.

# Path to gleaner (Better use environment variable PYTHONPATH!)
import os
glrPath = os.getenv('HOME')+'/apes/gleaner'
import sys

# Do not use X-server to create and save plot
import matplotlib
matplotlib.use('Agg')

## Import all required modules
import matplotlib.ticker as mtick
import matplotlib.pyplot as mplt
sys.path.append(glrPath)
import gleaner
import logging
import math

# font setting
from matplotlib import rc
font_size = 12
font_family = 'serif'
font_type = 'Times New Roman'
rc('text',usetex=True)
font = {'family':font_family,'%s'%font_family:font_type,'size':font_size}
rc('font',**font)

#axis without scientific notation
y_formatter = mtick.ScalarFormatter(useOffset=False)

# Analytical solution
length = 50e-9
permit = 8.854e-12*(80)
#ref_pot = -5e-3
#moleDens0 = 50 # 1 M = 1 mol/liter = 1e3 mol/m^3
valence_sqr = 1
charge = 1.6021e-19
faraday = 96485.3365
gasConst = 8.3144621
k_b = 1.3805e-23
temp = 298.15
N_A = 6.02e23 
from numpy import exp 
import numpy as np
x1 = np.linspace(-length/2.0, length/2.0,100)

def analy_pot_sym(x, moleDens,height, pot_1, pot_2):
  k = math.sqrt(2*moleDens*valence_sqr*faraday**2/(permit*gasConst*temp))*height
  #return cosh(k*(x/height))/cosh(k/2)*ref_pot
  pot = np.array([])
  for i in x:
    if i>0:
      pot = np.append(pot, np.cosh(k*(i/height))/np.cosh(k/2)*pot_1)
    else:
      pot = np.append(pot, np.cosh(k*(i/height))/np.cosh(k/2)*pot_2)
  return pot  

def analy_electric_field_sym(x, moleDens, height, pot_1, pot_2):
  k = math.sqrt(2*moleDens*valence_sqr*faraday**2/(permit*gasConst*temp))*height
  #return cosh(k*(x/height))/cosh(k/2)*ref_pot
  pot = np.array([])
  for i in x:
    if i>0:
      pot = np.append(pot, k*np.sinh(k*(i/height))/(height*np.cosh(k/2))*pot_1)
    else:
      pot = np.append(pot, k*np.sinh(k*(i/height))/(height*np.cosh(k/2))*pot_2)
  return -pot  

def analy_conc(x, moleDens, height, pot_1, pot_2, val):
  pot = analy_pot_sym(x, moleDens, height, pot_1, pot_2)
  fac = val*faraday/(gasConst*temp)
  return moleDens*exp(-fac*pot)

def analy_charge_dens(x, moleDens, height, pot_1, pot_2):
  pot = analy_pot_sym(x, moleDens, height, pot_1, pot_2)
  fac = faraday/(gasConst*temp)
  c_plus = moleDens*exp(-fac*pot)
  c_minus = moleDens*exp(fac*pot)
  return faraday*(c_plus - c_minus)

def convertToNumpy(x, fac, first=None, last=None):
  x_np = np.array([])
  if first:
    x_np = np.append(x_np, first*fac)

  for i in range(len(x)):
    x_np = np.append(x_np, x[i][0]*fac)

  if last:
    x_np = np.append(x_np, last*fac)

  return x_np
## -------------------------------------------------------------------------- ##
logging.basicConfig(level=logging.INFO)
## -------------------------------------------------------------------------- ##
logging.info('Started creating plots ...') 
 
import glob
import re
from operator import itemgetter

import sqlite3
# data base filename
dbname = 'ideal_Poisson.db'
# load database if exist else load tracking files and add to database
if os.path.isfile(dbname):
  print ('Processing data from existing database')
#  os.remove(dbname)
  sqlcon = sqlite3.connect(dbname)
else:
  print ('Processing data from tracking files')
  # Load text, dump into a database with specific tabname to get columns later
  sqlcon = gleaner.tracking_to_db(fname = 'tracking_Pot/*Pot_line*.res', \
                                  dbname=dbname, tabname='Pot')
## -------------------------------------------------------------------------- ##
print ('Pontential over height:')
get_data_for_cols = ['coordY','potential_phy']
fig = mplt.figure()
ax = fig.add_subplot(111)
moleDens0 = 100
print('EDL ',1.0/math.sqrt(2*moleDens0*valence_sqr*faraday**2/(permit*gasConst*temp)))
pot = 50e-3
analy_pot = analy_pot_sym(x1, moleDens0, length, -pot, pot)
mplt.plot(x1*1e9, analy_pot*1e3, 'x', color = 'r')
# Simulation result
[x, y] = gleaner.get_columns(sqlcon, tabname='Pot', \
                             columns=get_data_for_cols)
x, y = zip(*sorted(zip(x,y))) # sort of needed
xnew = convertToNumpy(x,1e9)
ynew = convertToNumpy(y,1e3)
mplt.plot(xnew, ynew, '-', color='k')

# plot setting
mplt.legend(loc=9, ncol=1,borderaxespad=0, \
            prop={'size':font_size}).get_frame().set_lw(0.0)
mplt.xlabel('y [nm]')
mplt.ylabel('Potential ($\psi$) [$mV$]')
mplt.grid(True,which="major",ls="-")
mplt.xlim(-25,-15)
mplt.ylim(-5,100)
ax.yaxis.set_major_formatter(y_formatter)

# save fig
figsize = [8,6]
fig = mplt.gcf()
fig.set_size_inches(figsize[0],figsize[1])
mplt.savefig('PotentialOverHeight.pdf', dpi=100, format='pdf', \
             bbox_inches="tight",interpolation=None)
## -------------------------------------------------------------------------- ##

mplt.show()
logging.info('Plots created')
