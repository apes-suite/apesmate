require 'params'
require 'track'
--debug = {logging = {level=5, filename='dbg_fluid', root_only=false}}
logging = {level=5, filename = 'log_fluid'}
-------------------------------------------------------------------------------
simulation_name = 'pipe_fluid'
timing_file = 'timing_fluid.res'
-------------------------------------------------------------------------------
mesh               = './mesh/'  
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
-------------------------------------------------------------------------------
diff_coeff = 1.0
-------------------------------------------------------------------------------
fluid    = { omega = omega, rho0 = rho_phy, kinematic_viscosity = nu_phy }
identify  = { 
  label      = 'fluid',
  kind       = 'fluid_incompressible',
  relaxation = 'mrt',
  layout     = 'd3q19'
}

initial_condition = { 
  pressure  = press_phy, 
  velocityX = 0.0,
  velocityY = 0.0,
  velocityZ = 0.0 
} 
boundary_condition = {  
  { label = 'vessel', kind = 'wall'}, 
  { label = 'inlet',
    kind     = 'velocity_bounceback',
    velocity = {uc,0.0,0.0}
  },
  { label     = 'outlet', 
    kind      = 'pressure_expol',
    pressure  = press_phy, 
  },
}
-------------------------------------------------------------------------------
start    = math.ceil(period_iter + period_iter/12.0)
NOrestart = {
  write = 'restart/',
  time_control = { 
    min      = { iter = tmax }, 
    max      = { iter = tmax }, 
    interval = { iter = tmax } 
  },
}
