require 'common'

simulation_name = 'jet_2d'

--debug = {logging = {level=1,filename='dbg_apes', root_only=false}}
logging = { level=10 }
--logging = { level=10,filename='log_apes' }

share_domain = true
sim_control = {
  time_control = { 
    max ={iter=10},
  }
}          
domain_object = {
  {
    label = 'ns',
    solver = 'ateles',
    filename = 'ateles_navier.lua',
    nProc_frac = 1
  },
  {
    label = 'ee',
    solver = 'ateles',
    filename = 'ateles_euler.lua',
    nProc_frac = 1 
  },
  {
    label = 'le',
    solver = 'ateles',
    filename = 'ateles_lineuler.lua',
    nProc_frac = 1
  }
}  
