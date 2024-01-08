require 'common'

simulation_name = 'tam'

--debug = {logging = {level=1,filename='dbg_apes', root_only=false}}
--logging = { level=10}
logging = { level=10, filename = 'log_apes'}

sim_control = {
  time_control = { 
    max =tmax,
    interval = {iter=100}        
  }
}          


nproc_is_frac = true
--total = 2624 
domain_object = {
  {
    label = 'dom_navier',
    solver = 'ateles',
    filename = 'ateles_navier.lua',
   -- nProc = 2000
    nProc_frac = 0.5
  },
  {
    label = 'dom_euler',
    solver = 'ateles',
    filename = 'ateles_euler.lua',
    --nProc = 304
    nProc_frac = 0.5
  },
  {
    label = 'dom_lineuler',
    solver = 'ateles',
    filename = 'ateles_lineuler.lua',
   -- nProc = 320 
    nProc_frac = 0.5
  }
}  
