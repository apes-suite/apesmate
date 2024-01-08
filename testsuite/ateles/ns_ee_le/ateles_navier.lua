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
logging = { level = 10, NOfilename = 'log_navier'}
simulation_name='ateles_navier' 
timing_file = 'timing_navier.res'

-- Restart -------------------------------------------------------------------
Norestart = {
--  read  = './restart/navier/ateles_navier_lastHeader.lua',
  write = './restart/navier/',
  time_control = {
    min = 0, 
    max = tmax, 
    interval = track_dt,
  },
}

-- Simulation parameter -------------------------------------------------------
mesh = 'mesh_navier/'

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
--  {
--    name = 'sponge',
--    ncomponents = 5,
--    vartype = "st_fun",
--    st_fun = {
--      predefined = "combined",
--      spatial = { 
--        predefined = 'spongelayer_2d', 
--        plane_origin = {20-20*elemsize+eps,-5.0+eps,0},
--        plane_normal = {20*elemsize,0,0},
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
--                    -5.0 ,
--                    -eps ,
--          },
--          vec = {{20*elemsize,0,0},
--                 {0,10,0},
--                 {0,0,elemsize}
--          },
--          segments = {320,640,16},
--        }, 
--      },
--    },
--  },
  {
    name = 'coupling_fluid',
    ncomponents = 12,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'ee',
      input_varname = {
        'density', 
        'velocity',
        'pressure',
        'gradX_density',
        'gradX_velX',
        'gradX_velY',
        'gradX_pressure',
        'gradY_density',
        'gradY_velX',
        'gradY_velY',
        'gradY_pressure'
     },
   }          
  },
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
     name = 'pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {4}
     }          
  },
  {
     name = 'gradX_density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {5}
     }          
  },
  {
     name = 'gradX_velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {6}
     }          
  },
  {
     name = 'gradX_velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {7}
     }          
  },
  {
     name = 'gradX_pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {8}
     }          
  },
  {
     name = 'gradY_density_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {5}
     }          
  },
  {
     name = 'gradY_velX_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {6}
     }          
  },
  {
     name = 'gradY_velY_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {7}
     }          
  },
  {
     name = 'gradY_pressure_euler',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_fluid',
       input_varindex = {8}
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
  name       = 'navier_stokes_2d',
  isen_coef  = gamma,
  r          = r,
  therm_cond = therm_cond,
  mu         = mu, 
  ip_param   = ip, 
  -- Parameters of the penalization
  porosity             = penalization_eps,
  viscous_permeability = penalization_alpha*penalization_eps,
  thermal_permeability = penalization_alpha*penalization_eps,
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
    label = 'fluid_west',
    kind = 'inflow_normal',     
    density = dens_inlet,
    v_norm = {
      predefined = "combined",
      spatial = velX_inlet,
      temporal = { predefined = 'smooth',  -- smooth sin function
                   min_factor = 0.0,
                   max_factor = 1.0,
                   from_time = 0,
                   to_time = 40.0
      },
    },
    v_tan = 0.0,
  },
  {
    -- this is now coupling to euler
    label = 'fluid_east',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = press,
  },
  {
    label = 'fluid_north',
    kind = 'grad_primitives',
    density = 'density_euler',
    velocityX = 'velX_euler', 
    velocityY = 'velY_euler',
    pressure = 'pressure_euler',
    grad_density   = 'gradY_density_euler',
    grad_velocityX = 'gradY_velX_euler', 
    grad_velocityY = 'gradY_velY_euler',
    grad_pressure  = 'gradY_pressure_euler',
  },
  {
    label = 'fluid_south',
    kind = 'grad_primitives',
    density = 'density_euler',
    velocityX = 'velX_euler', 
    velocityY = 'velY_euler',
    pressure = 'pressure_euler',
    grad_density   = 'gradY_density_euler',
    grad_velocityX = 'gradY_velX_euler', 
    grad_velocityY = 'gradY_velY_euler',
    grad_pressure  = 'gradY_pressure_euler',
  },
  {
    label = 'fluid_top',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = press,
  },
  {
    label = 'fluid_bottom',
    kind = 'primitives',
    density = dens,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = press,
  },
}
------------Sponge layer -----------------
--source = { spongelayer = 'sponge' }
