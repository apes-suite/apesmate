require 'params'
logging = { level=log_level, filename = 'log_fluid'}
-------------------------------------------------------------------------------
mesh               = './mesh/'  
simulation_name = 'cavity_fluid'
timing_file = timing_fluid
io_buffer_size = 16
-------------------------------------------------------------------------------
sim_control        = {
  time_control     = {
    min      = tstart,
    max      = tmax,
    interval = interval,
    check_iter = check_iter_num
  },
  delay_check = delay_check_ctl
}
timer = {
  file = timing_info_fluid,
  details = {
    {'overall', 'details'}
  }
}
-------------------------------------------------------------------------------
glob_source = {
  varname = 'bousinesseq',
  force = 'motivation',
  force_order = 2
}

variable = {
  {
    name = 'coeff',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = {0, -Pr * Ra, 0}
  },
  {
    name = 'T',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_T',
      input_varname = {'T_density'}
    } -- Uncomment this block for coupled simulation with temperature field solved by another solver
    -- st_fun = 0.1 -- Uncomment this line for individual fluid simulation without coupling
  },
  {
    name = 'motivation',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'multiply_scalar_times_vector',
      input_varname = {'T', 'coeff'},
    }
  }
}

physics  = { dt    = dt,    rho0 = rho_phy }
fluid    = { omega = 1./tau_f, rho0 = rho_phy, kinematic_viscosity = Pr }
identify = {
  label      = 'fluid',
  kind       = 'fluid_incompressible',
  relaxation = 'bgk',
  layout     = 'd3q19'
}
initial_condition = {
  pressure  = press_ref,
  velocityX = 0.0,
  velocityY = 0.0,
  velocityZ = 0.0
}
boundary_condition = {
  { label = 'left', kind = 'wall'},
  { label = 'right', kind = 'wall'},
  { label = 'up', kind = 'wall'},
  { label = 'down', kind = 'wall'},
  { label = 'front', kind = 'wall'},
  { label = 'back', kind = 'wall'}
}

balance = {
  dynamic = dynamic_balance_ctl,      
  time_control = {     
    min      = tstart,
    max      = tmax,
    interval = interval,
  },
}