NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=5, NOfilename = 'log_apes'}
timing_file = 'timing_aps.res'

-------------------------------------------------------------------------------
simulation_name = 'EOF'
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
tmax = 3000
interval = 100
sim_control        = { 
  time_control     = { 
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = interval } 
  }
 ,abort_criteria = {
    stop_file = './stop'
  }
}

share_domain = true 
nproc_is_frac = false -- true is default

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    filename = 'musubi_fluid.lua',
    nProc = 1
  },
  {
    label = 'dom_pb',
    solver = 'musubi',
    filename = 'musubi_PB.lua',
    nProc = 11
  },
}
