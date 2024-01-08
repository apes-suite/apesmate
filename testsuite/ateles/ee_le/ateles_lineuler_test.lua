-- Configuration file for Ateles --


-- This is a configuration file for the Finite Volume / Discontinuous Galerkin Solver ATELES. 
-- It provides a testcase for the simulation of Euler equations in a homogenous media. The simulation domain
-- is a periodic cube with edge length 2.0. Therefore this is a very good way to verify your algorithmic implementations, 
-- since this testcase does not involve any boundary conditions. 
-- The testcase simulates the temporal development of Gaussian pulse in density. Since we 
-- are considering a very simple domain, an analytic solution is well known and given as Lua functions in this script.
-- Therefore we suggest this testcase to verify one of the following topics
-- ... algorihtmic correctness
-- ... spatial and temporal order of your scheme
-- ... diffusion and dispersion relations of your scheme
-- ... and many more.
-- This testcase can be run in serial (only one execution unit) or in parallel (with multiple mpi ranks). 
-- To specify the number of ranks please modify nprocs variable. To calculate a grid convergence behavior please modify the 
-- level variable. An increment of one will half the radius of your elements.

timestep_info = 1

logging = {level=3}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
simulation_name='ateles_lineuler' 
degree = 1
tmax = 1.0
dt = 0.05
sim_control = {
             time_control = {
                  min = 0,
                  max = tmax, -- final simulation time
                  interval = {iter = 10}, -- final simulation time
                }
}

-- table for preCICE
precice = {
           accessor = 'Ateles_lineuler',
           configFile ='precice_config.xml',
          }

---- Restart settings
NOrestart = { 
  write = './restart/lineuler/',                                        
  time_control = { 
    min = 0, 
    max = tmax, 
    interval = {iter=1} 
  }
}

-- Tracking
tracking = {
  { -- GLobal VTK
    label = 'global',
    folder = './track/lineuler/',
    variable = {'density', 'momentum', 'energy'},
    shape = {
      { kind = 'all',}
    },
    time_control = {min = 0, max = tmax, interval = dt},
    output={format = 'vtk'},
  },
}


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
--  {
--     name = 'coupling',
--     ncomponents = 4,
--     vartype = 'st_fun',
--     st_fun = { 
--       predefined = 'precice',
--       precice_mesh = 'lineulerSurface',
--       write_varname = {'density_lineuler', 
--                        'velX_lineuler', 
--                        'velY_lineuler', 
--                        'pressure_lineuler'},
--       read_varname = {'density_euler', 
--                       'velX_euler', 
--                       'velY_euler', 
--                       'pressure_euler'},
--     }          
--   },
--  -- write to precice
--  {
--     name = 'density_lineuler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'addition',
--       input_varname = {'density','bg_density'},
--     }          
--  },
--  {
--     name = 'vel_lineuler',
--     ncomponents = 2,
--     vartype = 'operation',
--     operation = {
--       kind = 'addition',
--       input_varname = {'velocity','bg_velocity'},
--     }          
--  },
--  {
--     name = 'velX_lineuler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = {'vel_lineuler'},
--       input_varindex = {1}
--     }          
--  },
--  {
--     name = 'velY_lineuler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = {'vel_lineuler'},
--       input_varindex = {2}
--     }          
--  },
--
--  {
--     name = 'pressure_lineuler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'addition',
--       input_varname = {'pressure','bg_pressure'},
--     }          
--  },
--  -- read from precice
--  {
--     name = 'density_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = 'coupling',
--       input_varindex = {1}
--     }          
--  },
--  {
--     name = 'velX_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = 'coupling',
--       input_varindex = {2}
--     }          
--  },
--  {
--     name = 'velY_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = 'coupling',
--       input_varindex = {3}
--     }          
--  },
--  {
--     name = 'pressure_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = 'coupling',
--       input_varindex = {4}
--     }          
--  },
--  {
--     name = 'per_density_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'difference',
--       input_varname = {'density_euler','bg_density'},
--     }          
--  },
--  {
--     name = 'per_vel_euler',
--     ncomponents = 2,
--     vartype = 'operation',
--     operation = {
--       kind = 'difference',
--       input_varname = {'velocity','bg_velocity'},
--     }          
--  },
--  {
--     name = 'per_velX_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = {'per_vel_euler'},
--       input_varindex = {1}
--     }          
--  },
--  {
--     name = 'per_velY_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'extract',
--       input_varname = {'per_vel_euler'},
--       input_varindex = {2}
--     }          
--  },
--  {
--     name = 'per_pressure_euler',
--     ncomponents = 1,
--     vartype = 'operation',
--     operation = {
--       kind = 'difference',
--       input_varname = {'pressure_euler','bg_pressure'},
--     }          
--  },
}

-- Mesh definitions --
mesh = 'mesh_lineuler/'

-- timing settings (i.e. output for performance measurements, this table is otional)
timing_file = 'timing_lineuler.res'         -- the filename of the timing results

bg_dens = 1.0
bg_velX = 2.0
bg_velY = 0.0
bg_press = 10.0
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
      name = 'cfl',   -- the name of the timestep control mechanism
      cfl  = 0.8,     -- Courant–Friedrichs–Lewy number
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
