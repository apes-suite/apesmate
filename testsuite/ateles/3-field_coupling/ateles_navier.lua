require 'common'

-- initial condition --
initial_condition = {
  density = dens,
  velocityX = velX,
  velocityY = velY,
  velocityZ = velZ,
  pressure = { 
    predefined = 'gausspulse',
    center     = gp_center,
    halfwidth  = gp_halfwidth,
    amplitude  = gp_amplitude,
    background = gp_background
  },
}

-- simulation controll parameter-----------------------------------------------
logging = { level = 1, filename = 'log_navier'}
simulation_name='ateles_navier' 
timing_file = 'timing_navier.res'
degree = 2
-- Scheme definitions --
scheme = {
  -- the spatial discretization scheme
  spatial =  {
    name = 'modg',
    modg_space = 'Q',
    m = degree,
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

-- Restart -------------------------------------------------------------------
NOrestart = {
--  read  = './restart/navier/ateles_navier_lastHeader.lua',
  write = './restart/navier/',
  time_control = {
    min = 0, 
    max = tmax, 
  },
}

-- Tracking
--ply_sampling = { nlevels = 2}
segments = 20*(degree+1)
NOtracking = {
  -- Line tracking
  {
    label = 'navier_point',
    folder = './',
    variable = {'pressure', 'ref_pressure', 'error'},
    shape = {
      kind = 'canoND',
      object = {
        -- close to center
        { origin = { 0.375, 0.0, 0.0 }},
      },
    },
    time_control = {min = 0, max = tmax, interval = {iter=10}},
    output = { format = 'ascii', use_get_point = true},
  },
}

-- Simulation parameter -------------------------------------------------------
mesh = 'mesh_navier/'

-- Variable system definintion-------------------------------------------------

variable = {
  {
     name = 'ref_pressure',
     ncomponents = 1,
     vartype ='st_fun',
     st_fun = { 
       predefined = 'acoustic_pulse',
       center     = gp_center,
       halfwidth  = gp_halfwidth,
       amplitude  = gp_amplitude,
       background = gp_background,
       speed_of_sound = gp_c,
     }
  },
  {
     name = 'error',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'difference',
       input_varname = {'pressure', 'ref_pressure'},
    }
  },
  {
    name = 'coupling_fluid',
    ncomponents = 20,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_euler',
      input_varname = {
        'density', 
        'velocity',
        'pressure',
        'gradX_density',
        'gradX_velX',
        'gradX_velY',
        'gradX_velZ',
        'gradX_pressure',
        'gradY_density',
        'gradY_velX',
        'gradY_velY',
        'gradY_velZ',
        'gradY_pressure',
        'gradZ_density',
        'gradZ_velX',
        'gradZ_velY',
        'gradZ_velZ',
        'gradZ_pressure',
     },
   }          
  },
  -- read from precice
  {
     name = 'density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {1}
     }          
  },
  {
     name = 'velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {2}
     }          
  },
  {
     name = 'velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {3}
     }          
  },
  {
     name = 'velZ_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {4}
     }          
  },
  {
     name = 'pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {5}
     }          
  },
  {
     name = 'gradX_density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {6}
     }          
  },
  {
     name = 'gradX_velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {7}
     }          
  },
  {
     name = 'gradX_velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {8}
     }          
  },
  {
     name = 'gradX_velZ_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {9}
     }          
  },
  {
     name = 'gradX_pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {10}
     }          
  },
  {
     name = 'gradY_density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {11}
     }          
  },
  {
     name = 'gradY_velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {12}
     }          
  },
  {
     name = 'gradY_velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {13}
     }          
  },
  {
     name = 'gradY_velZ_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {14}
     }          
  },
  {
     name = 'gradY_pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {15}
     }          
  },
  {
     name = 'gradZ_density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {16}
     }          
  },
  {
     name = 'gradZ_velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {17}
     }          
  },
  {
     name = 'gradZ_velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {18}
     }          
  },
  {
     name = 'gradZ_velZ_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {19}
     }          
  },
  {
     name = 'gradZ_pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {20}
     }          
  },
}

-- Equation definitions -------------------------------------------------------
equation = {
  name       = 'navier_stokes',
  isen_coef  = gamma,
  r          = r,
  therm_cond = therm_cond, 
  mu         = mu,  
  ip_param   = ip_param, 
  -- Parameters of the penalization
    material = {
    characteristic = 0.0,
    relax_velocity = {0.0, 0.0, 0.0},
    relax_temperature = 0.0
  }
}
equation["cv"] = equation["r"] / (equation["isen_coef"] - 1.0)


 -- Boundary definitions
boundary_condition = {
  {
    label = 'coupling_fluid',
    kind = 'grad_primitives',
    density   = 'density_euler',
    velocityX = 'velX_euler', 
    velocityY = 'velY_euler',
    velocityZ = 'velZ_euler',
    pressure  = 'pressure_euler',
    grad_density   = 'gradX_density_euler',
    grad_velocityX = 'gradX_velX_euler', 
    grad_velocityY = 'gradX_velY_euler',
    grad_velocityZ = 'gradX_velZ_euler',
    grad_pressure  = 'gradX_pressure_euler',
  },
}
