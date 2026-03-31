require 'params'

NOdebug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=3, filename = 'log_apes'}

-------------------------------------------------------------------------------
simulation_name = 'stenosis_fullcoupling'
-------------------------------------------------------------------------------
io_buffer_size     = 16
-------------------------------------------------------------------------------
sim_control        = { 
  time_control     = { 
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = 1 } 
  }
}

nproc_is_frac = false
share_domain = true
-------------------------------------------------------------------------------
domain_object = {
  {
    label = 'dom_fluid',
    solver = 'musubi',
    -- filename = 'musubi_fluid.lua', -- uncomment to enable two-way coupling
    filename = 'musubi_fluid_no_interaction.lua',
    nProc = 192
  },
  {
    label = 'dom_T',
    solver = 'musubi',
    filename = 'musubi_ps.lua',
    -- nProc_frac = 1/6 --uncomment to enable nProc_frac
    nProc = 192
  }
}
