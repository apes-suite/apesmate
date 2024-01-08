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
                  max = {iter = 4000},
                  interval = {iter = 10}, 
                }
}
---- Restart settings
--restart = { 
--   --read = './restart/inner/ ateles_inner_header_98.000E-03.lua', 
--   write = './restart/left/',                                        
--   time_control = { 
--    min = 0, 
--    max = {iter=4000}, 
--    interval = {iter=400} 
--  }
--}

segments = 50*(degree+1)
tracking = {
   {
     label = 'lineX',
     variable = {'density', 'Xi', 'pressure'},
     shape = {
       kind = 'canoND',
       object = {
         -- close to center
         origin   = { -0.1, -0.05, 0.0},
         vec      = { 0.1, 0.0 ,0.0},
         segments = { segments},
       },
     },
    time_control = {min = 0, max = {iter=4000}, interval = {iter=4000}},
    output = { format = 'asciiSpatial', use_get_point = true},
    folder = './',
   }
}
-- Variable system definintion--
cylinder_radius = 0.01
function inside_cylinder(x,y,z,t)
  x0 = -0.05
  xc = x0 
  y0 = -0.05
  yc = y0 + 0.02 * math.sin(t*2*math.pi) 
  radius = math.sqrt((x-xc)^2 + (y-yc)^2)
  return (radius < cylinder_radius)
end
function velocityRelax(x,y,z,t)
    return {0.0, 0.02*(2*math.pi)* math.cos(t*2*math.pi)}
end
function characteristic(x,y,z,t)
  if inside_cylinder(x,y,z,t) then
    return 1.0
  else
    return 0.0
  end
end
dx = 0.015625
eps = 0.00001
variable = {
  { 
    name = 'Xi',
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      { const = 0.0 },
      {
         fun   = characteristic,
         shape = {
           kind = 'canoND',
           object = {
             origin = {
              -0.07 ,-0.09,-dx/2-eps
             },
             vec = {
               { 0.04, 0.0, 0.0 },
               { 0.0, 0.09, 0.0 },
               { 0.0, 0.0, dx*2 }
             },
             segments = { 50, 100, 50 }
           }
         }
      }
    }
  },
  { 
    name = 'relax_velocity',
    ncomponents = 2,
    vartype = "st_fun",
    st_fun = {
      { const = {0.0, 0.0} },
      {
         fun   = velocityRelax,
         shape = {
           kind = 'canoND',
           object = {
             origin = {
               -0.07,-0.09,-dx/2-eps
             },
             vec = {
               { 0.04, 0.0, 0.0 },
               { 0.0, 0.09, 0.0 },
               { 0.0, 0.0, dx*2 }
             },
             segments = { 50, 100, 50 }
           }
         }
      }
    }
  },
  {
     name = 'coupling_variable',
     ncomponents = 4,
     vartype = 'st_fun',
     st_fun = {0.0, 0.0, 0.0, 0.0} 
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


-- timing settings (i.e. output for performance measurements, this table is otional)
timing_file = 'timing_left.res'         -- the filename of the timing results

-- Equation definitions --
phi = 1.0
beta = 1e-6
eta_v = phi^2 * beta^2 
eta_t = 0.4 * phi * beta
equation = {
  name = 'euler_2d',
  numflux = 'hll',
  isen_coef = 1.4,
  r = 1.0/1.4,
  porosity             = phi,
  viscous_permeability = eta_v,
  thermal_permeability = eta_t,
  material = {
    characteristic = 'Xi',
    relax_velocity = 'relax_velocity',
    relax_temperature = pressure/(density*(1.0/1.4))
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
 -- stabilization = {
 --   {
 --      name  = 'spectral_viscosity',
 --      alpha = 32,
 --      order = 26
 --   }
 -- },
  -- the temporal discretization scheme
  temporal = {
    name = 'imexRungeKutta',  --'explicitEuler',
    steps = 4,
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
function iniVel(x,y,z,t)
  radius = math.sqrt(x^2 + y^2 )
  if inside_cylinder(x,y,z,0.0) then
    return 0.0
  else
    return velocityX 
  end
end
initial_condition = {
  density = density, 
  velocityX = iniVel,
  velocityY = 0.0,
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

