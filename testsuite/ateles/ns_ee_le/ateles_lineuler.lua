require 'common'
degree = 7
-- physical parameter ---------------------------------------------------------
initial_condition = {
  density = 0.0, 
  velocityX = 0.0,
  velocityY = 0.0,
  pressure = 0.0, 
}
bg_dens = dens
bg_velX = velocityX
bg_velY = velocityY
bg_press = press

-- simulation controll parameter-----------------------------------------------
logging = { level = 10, NOfilename = 'log_lineuler'}
simulation_name='ateles_lineuler'
timing_file = 'timing_lineuler.res'

-- Restart  -------------------------------------------------------------------
NOrestart = {
--  read  = './restart/lineuler/ateles_lineuler_lastHeader.lua',
  write = './restart/lineuler/',
  time_control = {
    min = 0, 
    max = tmax, 
    interval = track_dt
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
  {
    name = 'coupling_acoustic',
    ncomponents = 4,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'ee',
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
    name = 'pressure_euler',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'extract',
      input_varname = 'coupling_acoustic',
      input_varindex = {4}
    }          
  },
  -- linear euler domain need to linearized the variables read from euler domain
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
    ncomponents = 2,
    vartype = 'operation',
    operation = {
      kind = 'combine',
      input_varname = {'velX_euler','velY_euler'},
    }          
  },
  {
    name = 'per_vel_euler',
    ncomponents = 2,
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
  name = 'LinearEuler_2d',
  isen_coef = gamma,
  background = {
    density =  bg_dens,
    velocityX = bg_velX,
    velocityY = bg_velY,
    pressure = bg_press
  }
}

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
     order = filter_order_le,
     kind = 'poly',
     isAdaptive = false,  
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
    label = 'euler',
    kind = 'primitives',
    density = 'per_density_euler',
    velocityX = 'per_velX_euler', 
    velocityY = 'per_velY_euler',
    pressure = 'per_pressure_euler',
  },
  {
    label = 'fluid_north',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
  {
    label = 'fluid_south',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
  {
    label = 'fluid_west',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
  {
    label = 'fluid_east',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
  {
    label = 'fluid_bottom',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
  {
    label = 'fluid_top',
    kind = 'primitives',
    density = 0.0,
    velocityX = 0.0, 
    velocityY = 0.0,
    pressure = 0.0,
  },
}
