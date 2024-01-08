require 'common'

logging = {level=10, filename='log_right'}

-------------------------------------------
degree = 15
dt = 9e-5
track_name = './track/'
-------------------------------------------
-- global simulation options
simulation_name='ateles_right' 
sim_control = {
             time_control = {
                  min = 0,
                  max = tmax,
                  interval = {iter = 1},
                }
}

-- Tracking
tracking = {
  { 
    label = 'right',
    folder = track_name,
    variable = {'density', 'ref_density', 'error'},
    shape = {
      kind = 'canoND',
      object= { origin = { 0.01, 0.07, 0.25 } }
    },
    time_control = {min = 0, max = tmax, interval = {iter=1} },
    output = { format = 'ascii', use_get_point = true },
  },
}

-- Variable system definintion--
characteristic = 0.0
function relax_velocity(x,y,z,t)
  return {0.0, 0.0}
end
relax_temperature = 0.0

variable = {
  -- This is the global material for Euler 3D. It consists of three different
  -- components, characteristics with one scalar, relax_velocity with three
  -- scalars and relax_temperature with one scalar, thus we need five scalars
  -- for this equation system.
  -- As this is the global fallback material, we define each material to be a
  -- neutral term, which in this case is 0.
  {
     name = 'characteristic',
     ncomponents = 1,
     vartype = "st_fun",
     st_fun = characteristic
  },
  {
     name = 'relax_velocity',
     ncomponents = 2,
     vartype = "st_fun",
     st_fun = relax_velocity
  },
  {
     name = 'relax_temperature',
     ncomponents = 1,
     vartype = "st_fun",
     st_fun = relax_temperature
  },
  {
     name = 'ref_density',
     ncomponents = 1,
     vartype ='st_fun',
     st_fun = gauss,
  },
  {
     name = 'error',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'difference',
       input_varname = {'density', 'ref_density'},
     }
   },
  {
     name = 'coupling',
     ncomponents = 4,
     vartype = 'st_fun',
     st_fun = { 
       predefined = 'apesmate',
       domain_from = 'dom_left',
       input_varname = {'density', 'momentum', 'energy'}
     }          
  },
  {
     name = 'couplDens',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {1}
     }
  },
  {
     name = 'couplMomX',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {2}
     }
  },
  {
     name = 'couplMomY',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {3}
     }
  },
  {
     name = 'couplEnergy',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {4}
     }
  }
}

-- Mesh definitions --
mesh = 'mesh_right/'

-- timing settings (i.e. output for performance measurements, this table is otional)
timing_file = 'timing_right.res'         -- the filename of the timing results

-- Equation definitions --
equation = {
  name = 'euler_2d',
  therm_cond = 2.555e-02,
  isen_coef = 1.4,
  r = 296.0,
  material = {
    characteristic = 'characteristic',
    relax_velocity = 'relax_velocity',
    relax_temperature = 'relax_temperature'
  }
}
-- (cv) heat capacity and (r) ideal gas constant
equation["cv"] = equation["r"] / (equation["isen_coef"] - 1.0)

-- Scheme definitions --
scheme = {
  -- the spatial discretization scheme
  spatial =  {
    name = 'modg_2d',
    modg_space = 'Q',
    m = degree,
  },
  stabilization = {
    name = 'spectral_viscosity',
    alpha = 36,
    order = filter_order,
  },
  -- the temporal discretization scheme
  temporal = {
    name = 'explicitSSPRungeKutta',
    steps = 2,
    control = {
      name = 'fixed',
      dt = dt
    },
  },
}

-- Initial condition
initial_condition = {
  density = dens, 
  pressure = press, 
  velocityX = velocityX,
  velocityY = 0.0,
}

 -- Boundary definitions
boundary_condition = {
  {
    label = 'west',
    kind = 'conservatives',
    density = 'couplDens', 
    momentumX = 'couplMomX', 
    momentumY = 'couplMomY',
    energy = 'couplEnergy',
  }
  ,
  {
    label = 'east',
    kind = 'outflow',
    pressure = press,
  }
  ,
  {
    label = 'north',
    kind = 'primitives',
    density = dens, 
    velocityX = velocityX,
    velocityY = 0.0,
    pressure = press, 
  }
  ,
  {
    label = 'south',
    kind = 'primitives',
    density = dens, 
    velocityX = velocityX,
    velocityY = 0.0,
    pressure = press, 
  }
  ,
  {
    label = 'top',
    kind = 'primitives',
    density = dens, 
    velocityX = velocityX,
    velocityY = 0.0,
    pressure = press, 
  }
  ,
  {
    label = 'bottom',
    kind = 'primitives',
    density = dens, 
    velocityX = velocityX,
    velocityY = 0.0,
    pressure = press, 
  }

}
