require 'common'
degree = 7

-- Initial condition -----------------------------------!
initial_condition = { 
  density = dens,
  pressure = press,
  velocityX = 0.0,
  velocityY = 0.0,
}

-- simulation controll parameter-----------------------------------------------
logging = { level = 10, NOfilename = 'log_euler'}
simulation_name='ateles_euler'
timing_file = 'timing_euler.res'

-- Restart  -------------------------------------------------------------------
NOrestart = {
--  read  = './restart/euler/ateles_euler_lastHeader.lua',
  write = './restart/euler/',
  time_control = {
    min = 0, 
    max = tmax, 
    interval = track_dt
  },
}

-- Simulation parameter -------------------------------------------------------
mesh = 'mesh_euler/'

-- Variable system definintion-------------------------------------------------
characteristic = 0.0
function relax_velocity(x,y,z,t)
  return {0.0, 0.0}
end
relax_temperature = 0.0

variable = {
  {
    name = 'characteristic',
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = characteristic,
  },
  {
    name = 'relax_velocity',
    ncomponents = 2,
    vartype = "st_fun",
    st_fun = relax_velocity,
  },
  {
    name = 'relax_temperature',
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = relax_temperature,
  },
  {
    name = 'grad_density',
    ncomponents = 2,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'density',
    }          
  },
  {
    name = 'grad_velocity',
    ncomponents = 4,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'velocity',
    }          
  },
  {
    name = 'grad_pressure',
    ncomponents = 2,
    vartype = 'operation',
    operation = {
      kind = 'gradient',
      input_varname = 'pressure',
    }          
  },
--  {
--    name = 'sponge',
--    ncomponents = 5,
--    vartype = "st_fun",
--    st_fun = {
--      predefined = "combined",
--      spatial = { 
--        predefined = 'spongelayer_2d', 
--        plane_origin = {20-20*elemsize+eps,-10.0+eps,0},
--        plane_normal = {20*elemsize,0.0,0},
--        damp_factor = damp_factor,
--        damp_exponent = 1,
--        target_state = {
--           density = dens,
--           velx = velocityX,
--           vely = velocityY,
--           pressure = press,
--        }, 
--      },
--      shape = {
--        kind = 'canoND', 
--        object= {
--          origin = {
--                    20-20*elemsize+eps ,
--                    -10.0 ,
--                    -eps ,
--                    },
--          vec = {{20*elemsize,0,0},
--                 {0,20,0},
--                 {0,0,elemsize}},
--          segments = {320,1280,16},
--        }, 
--      },
--    },
--  },
  -- we have two coupling surface:
  {
    name = 'coupling_fluid',
    ncomponents = 4,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'ns',
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
    name = 'gradX_velY',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {3}
    }          
  },
  {
    name = 'gradY_velY',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'grad_velocity',
      input_varindex = {4}
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
    name = 'pressure_navier',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_fluid',
      input_varindex = {4}
    }          
  },
  -- coupling interface with acoustic domain
  {
    name = 'coupling_acoustic',
    ncomponents = 4,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'le',
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
    name = 'pressure_lineuler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {4}
    }          
  },
}

-- Equation definitions -------------------------------------------------------
penalization_eps = 8.0/(degree+1)
penalization_alpha = 1.0
equation = {
  penalization = {
    global = {
      kind = 'const',
      const = {0.0, 0.0, 0.0, 0.0},
    },
  },
  name       = 'euler_2d',
  isen_coef  = gamma,
  r          = r,
  material = {
    characteristic = 'characteristic',
    relax_velocity = 'relax_velocity',
    relax_temperature = 'relax_temperature'
  }
}
equation["cv"] = equation["r"] / (equation["isen_coef"] - 1.0)

-- Scheme definitions --
scheme = {
  spatial = {
    name = 'modg_2d',
    m = degree,
  }, 
  stabilization = {
    {
     name = 'spectral_viscosity',
     alpha = 36,
     order = filter_order,
     kind = 'poly',
     isAdaptive = adaptive,  
    },
  },
  temporal = {
    name = 'explicitSSPRungeKutta',
    steps = 2,
    control = {
      name = 'fixed',
      dt = dt
    },
  }
}  


 -- Boundary definitions
boundary_condition = {
  {
    label = 'navier',
    kind = 'primitives',
    density = 'density_navier',
    velocityX = 'velX_navier', 
    velocityY = 'velY_navier',
    pressure = 'pressure_navier',
  },
  {
    label = 'fluid_west',
    kind = 'inflow_normal',     
    density = dens_inlet,
    v_norm = velX_inlet,
    v_tan = 0.0,
  },
  {
    -- this is now coupling to lin euler
    label = 'fluid_east',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY, 
    pressure = press,
  },
  {
    label = 'fluid_north',
    kind = 'primitives',
    density = 'density_lineuler',
    velocityX = 'velX_lineuler', 
    velocityY = 'velY_lineuler',
    pressure = 'pressure_lineuler',
  },
  {
    label = 'fluid_south',
    kind = 'primitives',
    density = 'density_lineuler',
    velocityX = 'velX_lineuler', 
    velocityY = 'velY_lineuler',
    pressure = 'pressure_lineuler',
  },
  {
    label = 'fluid_bottom',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = press,
  },
  {
    label = 'fluid_top',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = press,
  },
}
------------Sponge layer -----------------
--source = { spongelayer = 'sponge' }
