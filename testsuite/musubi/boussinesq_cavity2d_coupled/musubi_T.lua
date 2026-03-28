require 'params'
------------------------------------------------------------------------
mesh               = './mesh/'  
simulation_name = 'cavity_T'
timing_file = 'timing_T.res'
logging = {level=3, filename = 'log_T'}
io_buffer_size = 16
-------------------------------------------------------------------------------
if if_print then
  print("h_2 = "..h_2)
  print("D = "..D)
end
----------------------------------------------------------------------------
sim_control        = {
  time_control     = {
    min      = tstart,
    max      = tmax,
    interval = interval
  }
}

physics  = { dt = dt,  rho0 = rho_phy }
-------------------------------------------------------------------------------
identify = {
  label      = 'species',
  kind       = 'passive_scalar',
  relaxation = 'trt',
  layout     = 'd2q9'
}
transport_velocity = 'velocity_fluid'
variable = {
  {
    name = 'velocity_fluid',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_fluid',
      input_varname = {'velocity_phy'}
    }
  }
}

field = { 
  label   = 'T',
  species = {
    diff_coeff = 1.
  },
  initial_condition = { pressure  = press_phy_low,
                        velocityX = 0.0,
                        velocityY = 0.0,
                        velocityZ = 0.0 
                      },
  boundary_condition = { 
      { 
        label = 'left', 
        kind = 'pressure_antibounceback',
        pressure = press_phy
      },
      { 
        label = 'right', 
        kind = 'pressure_antibounceback',
        pressure = press_phy_low
      },
      { label     = 'up',
        kind      = 'flekkoy_outlet'
      },
      { label     = 'down',
        kind      = 'flekkoy_outlet'
      }
    
  }
}

-- tracking = { 
--   { 
--     label     = 'T',
--     variable  = {'T_density'},
--     shape = {
--       kind = 'all'
--     },
--     folder    = tracking_folder,
--     output    = {format = 'vtk'},  
--     time_control     = { 
--       min = tstart , max = tmax , interval = interval }
--   }
-- }
-------------------------------------------------------------------------------
restart = {
  -- read  = 'restart/cavity_T_lastHeader.lua',
  write = 'restart/',
  time_control = {
    min      = tmax,
    max      = tmax,
    interval = tmax
  },
}
-------------------------------------------------------------------------------
