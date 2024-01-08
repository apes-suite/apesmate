## This is an example user-script for plotting performance data using the
## gleaner module.

# Path to gleaner (Better use environment variable PYTHONPATH!)
import matplotlib.pyplot as mplt
import matplotlib.ticker as mtick
import numpy as np
import sys
import os
home = os.getenv('HOME')
#sys.path.append('/home/gk780/gleaner')
sys.path.append('/home/ne808100/apes/gleaner')

from matplotlib import rc
rc('text',usetex=True)
font_size = 12
font_family='sans-serif'
font_type='sans-serif'
font = {'family':font_family,'%s'%font_family:font_type,'size':font_size}
rc('font',**font)

#axis without scientific notation
y_formatter = mtick.ScalarFormatter(useOffset=False)

# Import all required modules
import gleaner

import logging

print('Plot timeevolution for precice')

logging.basicConfig(level=logging.INFO)
## -------------------------------------------------------------------------- ##
# data base filename
dbname = 'LineX.db'
# load database if exist else load tracking files and add to database
if os.path.isfile(dbname):
  print ('Processing data from existing database')
#  os.remove(dbname)
  import sqlite3
  sqlcon = sqlite3.connect(dbname)
else:
  sqlcon = gleaner.tracking_to_db(fname = ['ateles_left_lineX_p*_t40.000E-03.res'], \
                                  dbname=dbname, tabname='LineX_left')
  sqlcon = gleaner.tracking_to_db(fname = ['ateles_right_lineX_p*_t40.000E-03.res'], \
                                  dbname=dbname, tabname='LineX_right')
print ('Ploting ')
fig = mplt.figure()
ax = fig.add_subplot(111)
get_data_for_cols = ['coordX','density','pressure']
[left_coordX, left_dens, left_pressure ] = gleaner.get_columns(sqlcon, \
                                                               tabname='LineX_left', \
                                                               columns=get_data_for_cols )
left_coordX, left_dens, left_pressure = zip(*sorted(zip(left_coordX,left_dens, left_pressure )))
[right_coordX, right_dens, right_pressure ] = gleaner.get_columns(sqlcon, \
                                                                  tabname='LineX_right', \
                                                                  columns=get_data_for_cols )
right_coordX, right_dens, right_pressure = zip(*sorted(zip(right_coordX,right_dens, right_pressure )))
mplt.plot(left_coordX, left_pressure, ls = '-', color = 'r', lw = 2.0, label = 'left pressure')
mplt.plot(right_coordX, right_pressure, ls = '-', color = 'm', lw = 2.0, label = 'right pressure')

mplt.legend(loc=1, ncol=2,borderaxespad=0, \
            prop={'size':font_size}).get_frame().set_lw(0.0)
mplt.xlabel('X')
mplt.ylabel('pressure')
mplt.grid()
#major_ticksX = np.arange(0,35,5) 
#major_ticksY = np.arange(0.71420, 0.71438,0.00002) 
#ax.set_xticks(major_ticksX)    
#ax.set_yticks(major_ticksY)    
#mplt.grid(True,which="major",ls="-")
#ax.yaxis.set_major_formatter(y_formatter)
#mplt.xlim(0, 35)
#mplt.ylim(0.7142, 0.71438)
  
# save fig
figsize = [6,4]
fig = mplt.gcf()
fig.set_size_inches(figsize[0],figsize[1])
mplt.savefig('LineX_pressure.pdf', dpi=100, format='pdf', \
               bbox_inches="tight",interpolation=None)
