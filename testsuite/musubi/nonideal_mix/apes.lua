require 'common'
NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=5, NOfilename = 'log_apes'}
timing_file = 'timing_aps.res'

-------------------------------------------------------------------------------
simulation_name = 'EOF'
printRuntimeInfo = true
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
tmax = 10 
interval = 100
sim_control        = { 
  time_control     = { 
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = interval },
    check_iter = 1
  }
 ,abort_criteria = {
    stop_file = './stop'
  }
}

share_domain = true 
nproc_is_frac = true -- true is default

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_PB',
    solver = 'musubi',
    filename = 'musubi_Poisson.lua',
    nProc_frac = 0.9,
    nProc = 11
  },
  {
    label = 'dom_MS',
    solver = 'musubi',
    filename = 'musubi_MS.lua',
    nProc_frac = 0.1,
    nProc = 1
  },
}
