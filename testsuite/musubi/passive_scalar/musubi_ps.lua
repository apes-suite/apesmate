require 'params'
require 'track'
--debug = {logging = {level=5, filename='dbg_ps', root_only=false}}
logging = {level=5, filename = 'log_ps'}
-------------------------------------------------------------------------------
simulation_name = 'pipe_ps'
timing_file = 'timing_ps.res'
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
function injection(x, y, z, t)
  if t > 1000 and  t <= tmax then
    return 1.0
  else
    return 0.0
  end 
end
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
diff_coeff = 0.2
-------------------------------------------------------------------------------
identify  = {
  label = 'species', 
  kind = 'passive_scalar', 
  relaxation='bgk', 
  layout='flekkoy' 
}

transport_velocity = 'velocity_fluid'

glob_source = {
  injection = injection 
}
variable = {
  {
    name = 'velocity_fluid',
    ncomponents = 3,
    vartype = 'st_fun',
    NOst_fun = {uc, 0.0, 0.0},
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_fluid',
      input_varname = {'velocity_phy'}
    }
  }
}
racking  = { 
  { label     = 'spc1',
    variable  = {'spc1_density'},
    shape = {
      kind  = 'canoND',
      object  = {
        origin = {-16.0, -0.5, 0.0},
        vec = {{31.0, 0.0, 0.0},
               {0.0, 1.0, 0.0} }
      }
    },
    folder    = 'tracking/',
    output    = {format = 'vtk'},  
    time_control     = { 
      min = { iter = 0 }, max = { iter = tmax }, interval = { iter = tmax/20 } }
  }
}

field = { 
  label   = 'spc1',
  species = {diff_coeff = {diff_coeff} },
  initial_condition = { pressure  = press_phy,
                        velocityX = 0.0,
                        velocityY = 0.0,
                        velocityZ = 0.0 
                      },
  boundary_condition = { { label = 'vessel', kind = 'wall'},
                         { label = 'inlet',
                           kind  = 'flekkoy_inlet'},
                         { label = 'outlet',
                           kind  = 'flekkoy_outlet' }
                       }
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
