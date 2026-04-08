require 'params'

-- NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=3, filename = 'log_apes'}

-------------------------------------------------------------------------------
simulation_name = 'cavity_coupling'
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
sim_control        = { 
  time_control     = { 
    min      = tstart,
    max      = tmax,
    interval = interval
  }
}

nproc_is_frac = false 
share_domain = true

domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    filename = 'musubi_fluid.lua',
    nProc = 4
  },
  {
    label = 'dom_T',
    solver = 'musubi',
    filename = 'musubi_T.lua',
    nProc = 4
  }
}
