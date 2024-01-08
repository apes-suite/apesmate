require 'common'
-- physical parameter ---------------------------------------------------------
initial_condition = {
  density = dens, 
  velocityX = velX,
  velocityY = velY,
  velocityZ = velZ,
  pressure = press, 
}

-- simulation controll parameter-----------------------------------------------
logging = { level = 1, filename = 'log_euler'}
simulation_name='ateles_euler'
timing_file = 'timing_euler.res'
degree = 4
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

-- Restart  -------------------------------------------------------------------
NOrestart = {
--  read  = './restart/euler/ateles_euler_lastHeader.lua', 
  write = './restart/euler/',
  time_control = {
    min = 0, 
    max = tmax, 
  },
}

-- Tracking -------------------------------------------------------------------
--ply_sampling = { nlevels = 2}
NOtracking = {
  {
    label = 'navier_euler',
    folder = './',
    variable = {'pressure', 'ref_pressure', 'error'},
    shape = {
      kind = 'canoND',
      object = {
        -- point west 
        { origin = { 0.625,0.0, 0.0 }},
      },
    },
    time_control = {min = 0, max = tmax, interval ={iter=10} },
    output = { format = 'ascii', use_get_point = true},
  },
  {
    label = 'euler_lineuler',
    folder = './',
    variable = {'pressure', 'ref_pressure', 'error'},
    shape = {
      kind = 'canoND',
      object = {
        -- point west 
        { origin = { 0.75,0.0, 0.0 }},
      },
    },
    time_control = {min = 0, max = tmax, interval ={iter=10} },
    output = { format = 'ascii', use_get_point = true},
  },
}

-- Simulation parameter -------------------------------------------------------
mesh = 'mesh_euler/'

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
    name = 'grad_density',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'density',
    }          
  },
  {
    name = 'grad_velocity',
    ncomponents = 9,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'velocity',
    }          
  },
  {
    name = 'grad_pressure',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'pressure',
    }          
  },
  -- we have to coupling surface:
  {
    name = 'coupling_fluid',
    ncomponents = 5,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_navier',
      input_varname = { 'density', 
                        'velocity',
                        'pressure',
      },
    },
  },
  -- gradient are required for coupling with navier domain
  {
    name = 'gradX_density',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_density',
      input_varindex = {1}
    }          
  },
  {
    name = 'gradY_density',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_density',
      input_varindex = {2}
    }          
  },
  {
    name = 'gradZ_density',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_density',
      input_varindex = {3}
    }          
  },
  {
    name = 'gradX_velX',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {1}
    }          
  },
  {
    name = 'gradY_velX',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {2}
    }          
  },
  {
    name = 'gradZ_velX',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {3}
    }          
  },
  {
    name = 'gradX_velY',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {4}
    }          
  },
  {
    name = 'gradY_velY',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {5}
    }          
  },
  {
    name = 'gradZ_velY',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {6}
    }          
  },
  {
    name = 'gradX_velZ',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {7}
    }          
  },
  {
    name = 'gradY_velZ',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {8}
    }          
  },
  {
    name = 'gradZ_velZ',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {9}
    }          
  },
  {
    name = 'gradX_pressure',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_pressure',
      input_varindex = {1}
    }          
  },
  {
    name = 'gradY_pressure',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_pressure',
      input_varindex = {2}
    }          
  },
  {
    name = 'gradZ_pressure',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_pressure',
      input_varindex = {3}
    }          
  },
  -- variables for the bc read from navier domain
  {
    name = 'density_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {1}
    }          
  },
  {
    name = 'velX_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {2}
    }          
  },
  {
    name = 'velY_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {3}
    }          
  },
  {
    name = 'velZ_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {4}
    }          
  },
  {
    name = 'pressure_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {5}
    }          
  },
  -- coupling interface with acoustic domain
  {
    name = 'coupling_acoustic',
    ncomponents = 5,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_lineuler',
      input_varname = { 'full_density', 
                        'full_velocity',
                        'full_pressure',
      },
    },
  },
  {
    name = 'density_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {1}
    }          
  },
  {
    name = 'velX_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {2}
    }          
  },
  {
    name = 'velY_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {3}
    }          
  },
  {
    name = 'velZ_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {4}
    }          
  },
  {
    name = 'pressure_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {5}
    }          
  },
}

-- Equation definitions -------------------------------------------------------
equation = {
  name       = 'euler',
  isen_coef  = gamma,
  r          = r,
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
    label = 'euler',
    kind = 'primitives',
    density = 'density_lineuler',
    velocityX = 'velX_lineuler', 
    velocityY = 'velY_lineuler',
    velocityZ = 'velZ_lineuler',
    pressure = 'pressure_lineuler',
  }
  ,
  {
    label = 'navier',
    kind = 'primitives',
    density = 'density_navier',
    velocityX = 'velX_navier', 
    velocityY = 'velY_navier',
    velocityZ = 'velZ_navier',
    pressure = 'pressure_navier',
  }
}
