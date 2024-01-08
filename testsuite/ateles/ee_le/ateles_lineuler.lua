-- Configuration file for Ateles --

timestep_info = 1

logging = {level=10, filename='log_lineuler'}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
simulation_name='ateles_lineuler' 
degree = 7
tmax = 0.25
dt = 0.1
sim_control = {
             time_control = {
                  min = 0,
                  max = tmax, -- final simulation time
                  interval = {iter = 10}, -- final simulation time
                }
}


---- Restart settings
NOrestart = { 
  write = './restart/lineuler/',                                        
  time_control = { 
    min = 0, 
    max = tmax, 
    interval = {iter=1000} 
  }
}

-- Tracking
tracking = {
 -- { -- GLobal VTK
 --   label = 'global',
 --   folder = './track/lineuler/',
 --   variable = {'density', 'velocity', 'pressure', 'full_density', 'full_velocity', 'full_pressure'},
 --   shape = {
 --     { kind = 'all',}
 --   },
 --   time_control = {min = 0, max = tmax, interval = dt},
 --   output={format = 'vtk'},
 -- },
  { -- GLobal VTK
    label = 'point',
    folder = './',
    variable = {'density', 'velocity', 'pressure', 'full_density', 'full_velocity', 'full_pressure'},
    shape = {
      { kind = 'canoND',
        object = {
          origin = {0.5625, 0.0, 0.03125}}}
    },
    time_control = {min = 0, max = tmax, interval = dt/10},
    output={format = 'ascii', use_get_point = true},
  },
}


bg_dens = 1.0
bg_velX = 0.0
bg_velY = 0.0
bg_press = 10.0
variable = {
  -- add the background to varSys
  {
    name = 'bg_density',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun =  bg_dens,  
  },
  {
    name = 'bg_velocity',
    ncomponents = 2,
    vartype = 'st_fun',
    st_fun =  {bg_velX, bg_velY}  
  },
  {
    name = 'bg_pressure',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun =  bg_press,  
  },
   -- get full states
  {
    name = 'full_density',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'addition',
      input_varname = {'density','bg_density'},
    }          
  },
  {
    name = 'full_velocity',
    ncomponents = 2,
    vartype = 'operation',
    operation = {
      kind = 'addition',
      input_varname = {'velocity','bg_velocity'},
    }          
  },
  {
     name = 'full_pressure',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'addition',
       input_varname = {'pressure','bg_pressure'},
     }          
  },

  {
    name = 'coupling',
    ncomponents = 4,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_euler',
      input_varname = { 'density', 'velocity', 'pressure'}
    }          
   },
  -- perturbation for boundaries
  {
     name = 'density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {1}
     }          
  },
  {
     name = 'velocity_euler',
     ncomponents = 2,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {2,3}
     }          
  },
  {
     name = 'pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {4}
     }          
  },
  {
     name = 'per_density',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'difference',
       input_varname = {'density_euler','bg_density'},
     }          
  },
  {
     name = 'per_vel',
     ncomponents = 2,
     vartype = 'operation',
     operation = {
       kind = 'difference',
       input_varname = {'velocity_euler','bg_velocity'},
     }          
  },
  {
     name = 'per_velX',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = {'per_vel'},
       input_varindex = {1}
     }          
  },
  {
     name = 'per_velY',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = {'per_vel'},
       input_varindex = {2}
     }          
  },
  {
     name = 'per_pressure',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'difference',
       input_varname = {'pressure_euler','bg_pressure'},
     }          
  },
}

-- Mesh definitions --
mesh = 'mesh_lineuler/'
--write_weights = './euler_weights'
-- timing settings (i.e. output for performance measurements, this table is otional)
--timing_file = 'timing_lineuler.res'         -- the filename of the timing results

-- Equation definitions --
equation = {
  name = 'LinearEuler_2d',
  therm_cond = 2.555e-02,
  isen_coef = 1.4,
  background = {
    density =  bg_dens,
    velocityX = bg_velX,
    velocityY = bg_velY,
    pressure = bg_press
  }
}

-- Scheme definitions --
scheme = {
  -- the spatial discretization scheme
  spatial =  {
    name = 'modg_2d',        -- we use the modal discontinuous Galerkin scheme 
    modg_space = 'Q',        -- the polynomial space Q or P
    m = degree,                   -- the maximal polynomial degree for each spatial direction
  },
  -- the temporal discretization scheme
  temporal = {
    name = 'explicitSSPRungeKutta',  --'explicitEuler',
    steps = 2,
    -- how to control the timestep
    control = {
      name = 'fixed',   -- the name of the timestep control mechanism
      dt  = 0.0001,     
    },
  },
}

-- ...the general projection table
projection = {
  kind = 'l2p',  -- 'fpt' or 'l2p', default 'l2p'
  factor = 1.0,          -- dealising factpr for fpt, oversampling factor for l2p, float, default 1.0
}

-- This is a very simple example to define constant boundary condtions.
-- Transport velocity of the pulse in x direction.
initial_condition = {
  density = 0.0, 
  velocityX = 0.0, 
  velocityY = 0.0,
  pressure = 0.0, 
}

 -- Boundary definitions
boundary_condition = {
  {
    label = 'euler',
    kind = 'primitives',
    density = 'per_density',
    velocityX = 'per_velX', 
    velocityY = 'per_velY',
    pressure = 'per_pressure',
  }
  ,
  {
    label = 'west',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }
  ,
  {
    label = 'east',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }
  ,
  {
    label = 'north',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }
  ,
  {
    label = 'south',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }
  ,
  {
    label = 'top',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }
  ,
  {
    label = 'bottom',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  }

}
