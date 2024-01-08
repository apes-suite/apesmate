require 'params'
require 'track'

NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=5, filename = 'log_apes'}

-------------------------------------------------------------------------------
simulation_name = 'pipe'
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
interval           = 100
sim_control        = { 
  time_control     = { 
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = interval } 
  }
}

nproc_is_frac = false -- true is default

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    filename = 'musubi_fluid.lua',
    nProc = 4
  },
  {
    label = 'dom_ps',
    solver = 'musubi',
    filename = 'musubi_ps.lua',
    nProc = 4
  }
}
