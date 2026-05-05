require 'params'
-- require 'musubi'

-- NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=3, filename = 'log_apes'}

-------------------------------------------------------------------------------
simulation_name = 'stenosis_fullcoupling'
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
-- interval           = 100
sim_control        = { 
  time_control     = { 
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = 1 } 
  }
}

nproc_is_frac = true
shared_domain = true
-------------------------------------------------------------------------------

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    -- filename = 'musubi_fluid.lua',
    filename = 'musubi_fluid_no_interaction.lua',
    -- nProc = 192
    nProc_frac = 1/2
  },
  {
    label = 'dom_T',
    solver = 'musubi',
    filename = 'musubi_ps.lua',
    nProc_frac = 1/2
    -- nProc = 192
  }
}

