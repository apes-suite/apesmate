-- Configuration file for Ateles --
require 'common'

timestep_info = 1

logging = {level=10,filename ='log_right'}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
simulation_name='ateles_right' 
degree = 5
sim_control = {
             time_control = {
                  min = 0,
                  max = {iter=2000}, -- final simulation time
                  interval = {iter = 10}, -- final simulation time
                }
}


segments = 50*(degree+1)
-- Tracking

tracking = {
 {
   label = 'lineX',
   variable = {'density', 'ref_density', 'error'},
   shape = {
     kind = 'canoND',
     object = {
       -- close to center
       origin   = { 0.0, -0.125, 0.0 },
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
     name = 'coupling_variable',
     ncomponents = 4,
     vartype = 'st_fun',
     st_fun = { 
       predefined = 'apesmate',
       domain_from = 'left_domain',
       input_varname = {'density', 'momentum', 'energy'}
     }          
  },
   {
     name = 'density_left',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_variable',
       input_varindex = {1}}
  },
  {
     name = 'MomentumX_left',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_variable',
       input_varindex = {2}}
  },
  { 
     name = 'MomentumY_left',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_variable',
       input_varindex = {3}}
  },
  {
     name = 'Energy_left',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling_variable',
       input_varindex = {4}}
   },
}

-- Mesh definitions --
mesh = 'mesh_right/'

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

-- This is a very simple example to define constant boundary condtions.
-- Transport velocity of the pulse in x direction.
initial_condition = {
  density = ic_gauss, 
  velocityX = velocityX,
  velocityY = velocityY,
  pressure  = pressure,
}
-- Boundary definitions
boundary_condition = {
  {
    label = 'west',
    kind = 'conservatives',
    density = 'density_left',
    momentumX = 'MomentumX_left', 
    momentumY = 'MomentumY_left',
    energy = 'Energy_left',
  }
  ,
  {
    label = 'east',
    kind = 'outflow',
    pressure = pressure,
  }
  ,
  {
    label = 'north',
    kind = 'outflow',
    pressure = pressure,
  }
  ,
  {
    label = 'south',
    kind = 'outflow',
    pressure = pressure,
  }
  ,
  {
    label = 'top',
    kind = 'outflow',
    pressure = pressure,
  }
  ,
  {
    label = 'bottom',
    kind = 'outflow',
    pressure = pressure,
  }

}
