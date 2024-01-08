-- Configuration file for Ateles --

timestep_info = 1

--logging = {level=3}
logging = {level=10, filename='log_euler'}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
simulation_name='ateles_euler' 
degree= 5
tmax = 0.25
dt = 0.1
sim_control = {
             time_control = {
                  min = 0,
                  max = tmax,
                  interval = {iter = 10}, -- final simulation time
                }
}

---- Restart settings
NOrestart = { 
  write = './restart/euler/',                                        
  time_control = { 
    min = 0, 
    max = tmax, 
    interval = {iter=1} 
  }
}

-- Tracking
NOtracking = {
  { -- GLobal VTK
    label = 'global',
    folder = './track/euler/',
    variable = {'density', 'momentum', 'energy', 'pressure', 'velocity'},
    shape = {
      { kind = 'all',}
    },
    time_control = {min = 0, max = tmax, interval = dt},
    output={format = 'vtk'},
  },
}

-- Variable system definintion--

variable = {
  {
     name = 'coupling',
     ncomponents = 4,
     vartype = 'st_fun',
     st_fun = { 
       predefined = 'apesmate',
       domain_from = 'dom_lineuler',
       input_varname = {'full_density', 'full_velocity', 'full_pressure'}
     }          
   },
  {
     name = 'coupl_density',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {1}
     }          
  },
  {
     name = 'coupl_velX',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {2}
     }          
  },
  {
     name = 'coupl_velY',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {3}
     }          
  },
  {
     name = 'coupl_pressure',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {4}
     }          
  }
}

-- Mesh definitions --
mesh = 'mesh_euler/'
--write_weights = './euler_weights'

-- timing settings (i.e. output for performance measurements, this table is otional)
--timing_file = 'timing_euler.res'         -- the filename of the timing results

-- Equation definitions --
equation = {
  name = 'euler_2d',
  therm_cond = 2.555e-02,
  isen_coef = 1.4,
  r = 296.0,
  material = {
    characteristic = 0.0,
    relax_velocity = {0.0,0.0},
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
      name = 'fixed',   -- the name of the timestep control mechanism
      dt   = 0.0001,     
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
dens = 1.0
velocityX = 0.0
press = 10.0

function gauss_press (x,y,z)
d= (x)*(x)+y*y 
return( press + 2.0* math.exp(-d/0.005*math.log(2)) )
end 

initial_condition = {
  density = dens, 
  pressure = gauss_press, 
  velocityX = velocityX,
  velocityY = 0.0,
}

 -- Boundary definitions
boundary_condition = {
  {
    label = 'west',
    kind = 'primitives',
    density = 'coupl_density',
    velocityX = 'coupl_velX',
    velocityY = 'coupl_velY',
    pressure = 'coupl_pressure',
  }
  ,
  {
    label = 'east',
    kind = 'primitives',
    density = 'coupl_density',
    velocityX = 'coupl_velX',
    velocityY = 'coupl_velY',
    pressure = 'coupl_pressure',
  }
  ,
  {
    label = 'north',
    kind = 'primitives',
    density = 'coupl_density',
    velocityX = 'coupl_velX',
    velocityY = 'coupl_velY',
    pressure = 'coupl_pressure',
  }
  ,
  {
    label = 'south',
    kind = 'primitives',
    density = 'coupl_density',
    velocityX = 'coupl_velX',
    velocityY = 'coupl_velY',
    pressure = 'coupl_pressure',
  }
  ,
  {
    label = 'top',
    kind = 'slipwall',
  }
  ,
  {
    label = 'bottom',
    kind = 'slipwall',
  }

}
