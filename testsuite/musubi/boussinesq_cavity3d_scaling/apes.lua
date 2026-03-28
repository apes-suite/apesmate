require 'params'

-- NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=log_level, filename = 'log_apes'}
timing_file = timing_apes
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

timer = {
  file = timing_info_apes,
  details = {
    {'overall', 'details'}
  }
}

share_domain = true
nproc_is_frac = true

domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    filename = 'musubi_fluid.lua',
    nProc_frac = 1/2
  },
  {
    label = 'dom_T',
    solver = 'musubi',
    filename = 'musubi_T.lua',
    nProc_frac = 1/2
  }
}