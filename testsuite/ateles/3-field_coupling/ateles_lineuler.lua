require 'common'
-- physical parameter ---------------------------------------------------------
initial_condition = {
  density = 0.0, 
  velocityX = 0.0,
  velocityY = 0.0,
  velocityZ = 0.0,
  pressure = 0.0, 
}
bg_dens = dens
bg_velX = velX
bg_velY = velY
bg_velZ = velZ
bg_press = press

-- simulation controll parameter-----------------------------------------------
logging = { level = 1, filename = 'log_lineuler'}
simulation_name='ateles_lineuler'
timing_file = 'timing_lineuler.res'
degree = 6
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
--  read  = './restart/lineuler/ateles_lineuler_lastHeader.lua',
  write = './restart/lineuler/',
  time_control = {
    min = 0, 
    max = tmax, 
  },
}

-- Tracking -------------------------------------------------------------------
tracking = {
  {
    label = 'lineuler',
    folder = './',
    variable = {'full_pressure', 'ref_pressure', 'error'},
    shape = {
      kind = 'canoND',
      object = {
        -- point west 
        { origin = { 1.25, 0.0, 0.0 }},
      },
    },
    time_control = {min = 0, max = tmax, interval ={iter=10} },
    output = { format = 'ascii', use_get_point = true},
  },
}

-- Simulation parameter -------------------------------------------------------
mesh = 'mesh_lineuler/'

-- Variable system definintion-------------------------------------------------

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
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun =  {bg_velX, bg_velY, bg_velZ}  
  },
  {
    name = 'bg_pressure',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun =  bg_press,  
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
       input_varname = {'full_pressure', 'ref_pressure'},
    }
  },
  {
    name = 'coupling_acoustic',
    ncomponents = 5,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_euler',
      input_varname = { 'density', 
                        'velocity',
                        'pressure',
      },
    },
  },
  -- write to euler domain full state is required
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
    ncomponents = 3,
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
  --read coupling interface acoustic 
  {
    name = 'density_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {1}
    }          
  },
  {
    name = 'velX_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {2}
    }          
  },
  {
    name = 'velY_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {3}
    }          
  },
  {
    name = 'velZ_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {4}
    }          
  },
  {
    name = 'pressure_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {5}
    }          
  },
  {
    name = 'per_density_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'difference',
      input_varname = {'density_euler','bg_density'},
    }          
  },
  {
    name = 'velocity_euler',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'combine',
      input_varname = {'velX_euler','velY_euler', 'velZ_euler'},
    }          
  },
  {
    name = 'per_vel_euler',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'difference',
      input_varname = {'velocity_euler','bg_velocity'},
    }          
  },
  {
    name = 'per_velX_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = {'per_vel_euler'},
      input_varindex = {1}
    }          
  },
  {
    name = 'per_velY_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = {'per_vel_euler'},
      input_varindex = {2}
    }          
  },
  {
    name = 'per_velZ_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = {'per_vel_euler'},
      input_varindex = {3}
    }          
  },
  {
    name = 'per_pressure_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'difference',
      input_varname = {'pressure_euler','bg_pressure'},
    }          
  },
}


-- Equation definitions -------------------------------------------------------
equation = {
  name = 'LinearEuler',
  isen_coef = gamma,
  background = {
    density =  bg_dens,
    velocityX = bg_velX,
    velocityY = bg_velY,
    velocityZ = bg_velZ,
    pressure = bg_press
  }
}

 -- Boundary definitions
boundary_condition = {
  {
    label = 'coupling_euler',
    kind = 'primitives',
    density = 'per_density_euler',
    velocityX = 'per_velX_euler', 
    velocityY = 'per_velY_euler',
    velocityZ = 'per_velZ_euler',
    pressure = 'per_pressure_euler',
  }
  ,
  {
    label = 'lineuler',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    velocityZ = 0.0,
    pressure = 0.0,
  }
}
