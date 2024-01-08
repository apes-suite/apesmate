-- Configuration file for Ateles --
require 'common'

timestep_info = 1

logging = {level=10,filename ='log_left'}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
degree= 5

simulation_name='ateles_left' 
sim_control = {
             time_control = {
                  min = 0,
                  max = {iter = 2000},
                  interval = {iter = 10}, -- final simulation time
                }
}

segments = 50*(degree+1)
tracking = {
   {
     label = 'lineX_left_density',
     variable = {'density', 'ref_density', 'error'},
     shape = {
       kind = 'canoND',
       object = {
         -- close to center
         origin   = { -0.25, -0.125, 0.0},
         vec      = { 0.25, 0.0 ,0.0},
         segments = { segments},
       },
     },
    time_control = {min = 0, max = {iter=2000}, interval={iter=2000}},
    output = { format = 'asciiSpatial', use_get_point = true},
    folder = './',
   }
}
-- Variable system definintion--
variable = {
  {
     name = 'ref_density',
     ncomponents = 1,
     vartype ='st_fun',
     st_fun = gauss 
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
     name = 'coupling_variable',
     ncomponents = 4,
     vartype = 'st_fun',
     st_fun = { 
       predefined = 'apesmate',
       domain_from = 'right_domain',
       input_varname = {'density', 'momentum','energy'} 
     }          
   },
    {
       name = 'density_right',
       ncomponents = 1,
       vartype = 'operation',
       operation = {
         kind = 'extract',
         input_varname = 'coupling_variable',
         input_varindex = {1}}
    },
    {
       name = 'MomentumX_right',
       ncomponents = 1,
       vartype = 'operation',
       operation = {
         kind = 'extract',
         input_varname = 'coupling_variable',
         input_varindex = {2}}
    },
    {
       name = 'MomentumY_right',
       ncomponents = 1,
       vartype = 'operation',
       operation = {
         kind = 'extract',
         input_varname = 'coupling_variable',
         input_varindex = {3}}
    },
   {
      name = 'Energy_right',
      ncomponents = 1,
      vartype = 'operation',
      operation = {
        kind = 'extract',
        input_varname = 'coupling_variable',
        input_varindex = {4}}
    },
}


-- Mesh definitions --
mesh = 'mesh_left/'

-- Equation definitions --
equation = {
  name = 'euler_2d',
  therm_cond = 2.555e-02,
  isen_coef = 1.4,
  r = 296.0,
  material = {
    characteristic = 0.0,
    relax_velocity = {0.0, 0.0},
    relax_temperature = 0.0
  }
}
-- (cv) heat capacity and (r) ideal gas constant
equation["cv"] = equation["r"] / (equation["isen_coef"] - 1.0)

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
        name = 'fixed',
        dt = 0.00001,
    },
  },
}

-- ...the general projection table
projection = {
  kind = 'l2p',  -- 'fpt' or 'l2p', default 'l2p'
  factor = 1.0,          -- dealising factpr for fpt, oversampling factor for l2p, float, default 1.0
}
initial_condition = {
  density = ic_gauss, 
  velocityX = velocityX,
  velocityY = velocityY,
  pressure  = pressure
}

 -- Boundary definitions
boundary_condition = {
  {
    label = 'west',
    kind = 'primitives',
    density = density,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = pressure,
  }
  ,
  {
    label = 'east',
    kind = 'conservatives',
    density = 'density_right',
    momentumX = 'MomentumX_right', 
    momentumY = 'MomentumY_right',
    energy = 'Energy_right',
  }
  ,
  {
    label = 'north',
    kind = 'primitives',
    density = density,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = pressure,

  },
  {
    label = 'south',
    kind = 'primitives',
    density = density,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = pressure,

  },
  {
    label = 'top',
    kind = 'primitives',
    density = density,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = pressure,
  },
  {
    label = 'bottom',
    kind = 'primitives',
    density = density,
    velocityX = velocityX, 
    velocityY = velocityY,
    pressure = pressure,
  }
}

