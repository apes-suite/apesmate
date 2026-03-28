require 'params'
------------------------------------------------------------------------
mesh               = './mesh/'  
simulation_name = 'cavity_T'
timing_file = timing_T
logging = {level=log_level, filename = 'log_T'}
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
    interval = interval,
    check_iter = check_iter_num
  },
  delay_check = delay_check_ctl
}

physics  = { dt = dt,  rho0 = rho_phy }
-------------------------------------------------------------------------------
identify = {
  label      = 'species',
  kind       = 'passive_scalar',
  relaxation = {
    name = 'bgk',
    variant = 'first'
  },
  layout     = 'd3q19',
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
    } --Uncomment this block for coupled simulation with velocity field solved by another solver
    -- st_fun = {10, 5, -5} -- Uncomment this line for individual temperature simulation without coupling
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
      },
      { label     = 'front',
        kind      = 'flekkoy_outlet'
      },
      { label     = 'back',
        kind      = 'flekkoy_outlet'
      }
  }
}

timer = {
  file = timing_info_T,
  details = {
    {'overall', 'details'}
  }
}

balance = {
  dynamic = dynamic_balance_ctl,      
  time_control = {     
    min      = tstart,
    max      = tmax,
    interval = interval,
  },
}