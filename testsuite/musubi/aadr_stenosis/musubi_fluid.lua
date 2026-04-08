require 'params'
logging = { level=3, filename = 'log_fluid_unsteady'}
-------------------------------------------------------------------------------
mesh               = './mesh/'  
simulation_name = 'stenosis_flow_unsteady'
timing_file = 'timing_flow_steady.res'
io_buffer_size = 16
-------------------------------------------------------------------------------
-- Imposing a gradually increasing velocity at the inlet to avoid numerical instability at the beginning of the simulation. The velocity will reach the target value at time_point * dt + t_needed.
function u_in_linear(x, y, z, t)
  local u_t = {0, 0, 0}
  local t_fold = 5 -- fold of time needed going over the length
  local t_needed = length / dx * t_fold * dt
  if if_print then
    print("t_needed = "..t_needed)
  end
  
  if t < t_needed then
    u_t[1] = u_ave * t / t_needed
  else
    u_t[1] = u_ave
  end
  return u_t
end
-- u_in_linear(0, 0, 0, 0) --- IGNORE ---
-------------------------------------------------------------------------------
sim_control        = {
  time_control     = {
    min      = { iter = 0        },
    max      = { iter = tmax     },
    interval = { iter = 1 }
  }
}
-------------------------------------------------------------------------------
glob_source = {
  varname = 'porous',
  brinkman = 'T_source',
}
variable = {
  {
    name = 'T_source',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_T',
      input_varname = {'T_density'}
    }
  }
}
physics  = { dt    = dt,    rho0 = rho_phy }
fluid    = { omega = 1./tau, rho0 = rho_phy, kinematic_viscosity = nu_phy }
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
  { label = 'front', kind = 'wall'},
  { label = 'middle', kind = 'wall'},
  { label = 'end', kind = 'wall'},
  { label     = 'inlet',
    kind      = 'velocity_bounceback',
    velocity  = {u_ave, 0.0, 0.0},
  },
  { label     = 'outlet',
    kind      = 'pressure_expol',
    pressure  = press_ref,
  }
}
-------------------------------------------------------------------------------
tracking = { 
  { label     = 'fluid',
    variable  = {'velocity_phy', 'pressure_phy'},
    shape = {
      kind = 'all'
    },
    folder    = tracking_folder,
    output    = {format = 'vtk'},  
    time_control     = { 
      min = { iter = tmax }, max = { iter = tmax }, interval = { iter = tmax } }
  }
}
-------------------------------------------------------------------------------
restart = {
  read  = 'restart/stenosis_flow_steady_lastHeader.lua',
  -- write = 'restart_1/',
  -- time_control = {
  --   min      = { iter = tmax  },
  --   max      = { iter = tmax  },
  --   interval = { iter = tmax  }
  -- },
}
-------------------------------------------------------------------------------
