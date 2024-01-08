-- Configuration file for Ateles --


-- This is a configuration file for the Finite Volume / Discontinuous Galerkin Solver ATELES. 
-- It provides a testcase for the simulation of Euler equations in a homogenous media. The simulation domain
-- is a periodic cube with edge length 2.0. Therefore this is a very good way to verify your algorithmic implementations, 
-- since this testcase does not involve any boundary conditions. 
-- The testcase simulates the temporal development of Gaussian pulse in density. Since we 
-- are considering a very simple domain, an analytic solution is well known and given as Lua functions in this script.
-- Therefore we suggest this testcase to verify one of the following topics
-- ... algorihtmic correctness
-- ... spatial and temporal order of your scheme
-- ... diffusion and dispersion relations of your scheme
-- ... and many more.
-- This testcase can be run in serial (only one execution unit) or in parallel (with multiple mpi ranks). 
-- To specify the number of ranks please modify nprocs variable. To calculate a grid convergence behavior please modify the 
-- level variable. An increment of one will half the radius of your elements.

timestep_info = 1

--logging = {level=10}
logging = {level=10, filename='log_left'}

-- Check for Nans and unphysical values
check =  {
           interval = 1,
         }

-- global simulation options
simulation_name='ateles_left' 
tmax = 2.0
dt = 0.1
sim_control = {
             time_control = {
                  min = 0,
                  max = tmax, -- final simulation time
                  interval = {iter=1} 
                }
}

---- Restart settings
NOrestart = { 
--read = './restart/twoway/left/simulation_lastHeader.lua',                        
  write = './restart/left/',                                        
  -- temporal definition of restart write
  time_control = { 
    min = 0, 
    max = fin_time, 
    interval = {iter=10} 
  }
}

-- Tracking
tracking = {
  { -- GLobal VTK
    label = 'global',
    folder = './track/left/',
    variable = {'density', 'momentum', 'energy'},
    shape = {
      { kind = 'all',}
    },
    time_control = {min = 0, max = tmax, interval = dt},
    output={format = 'vtk'},
  },
}
-- Variable system definintion--
characteristic = 0.0
function relax_velocity(x,y,z,t)
  return {0.0, 0.0, 0.0}
end
relax_temperature = 0.0

variable = {
  -- This is the global material for Euler 3D. It consists of three different
  -- components, characteristics with one scalar, relax_velocity with three
  -- scalars and relax_temperature with one scalar, thus we need five scalars
  -- for this equation system.
  -- As this is the global fallback material, we define each material to be a
  -- neutral term, which in this case is 0.
  {
     name = 'characteristic',
     ncomponents = 1,
     vartype = "st_fun",
     st_fun = characteristic
  },
  {
     name = 'relax_velocity',
     ncomponents = 3,
     vartype = "st_fun",
     st_fun = relax_velocity
  },
  {
     name = 'relax_temperature',
     ncomponents = 1,
     vartype = "st_fun",
     st_fun = relax_temperature
  },
  {
     name = 'coupling',
     ncomponents = 5,
     vartype = 'st_fun',
     st_fun = { 
       predefined = 'apesmate',
       domain_from = 'dom_right',
       input_varname = {'density', 'momentum', 'energy'}
     }          
  },
  {
     name = 'couplDens',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {1}
     }
  },
  {
     name = 'couplMomX',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {2}
     }
  },
  {
     name = 'couplMomY',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {3}
     }
  },
  {
     name = 'couplMomZ',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {4}
     }
  },
  {
     name = 'couplEnergy',
     ncomponents = 1,
     vartype = 'operation',
     operation = {
       kind = 'extract',
       input_varname = 'coupling',
       input_varindex = {5}
     }
  }
}

-- Mesh definitions --
mesh = 'mesh_left/'


-- timing settings (i.e. output for performance measurements, this table is otional)
timing_file = 'timing_left.res'         -- the filename of the timing results

-- Equation definitions --
equation = {
  name = 'euler',
  therm_cond = 2.555e-02,
  isen_coef = 1.4,
  r = 296.0,
  material = {
    characteristic = 'characteristic',
    relax_velocity = 'relax_velocity',
    relax_temperature = 'relax_temperature'
  }
}
-- (cv) heat capacity and (r) ideal gas constant
equation["cv"] = equation["r"] / (equation["isen_coef"] - 1.0)

-- Scheme definitions --
scheme = {
  -- the spatial discretization scheme
  spatial =  {
    name = 'modg',           -- we use the modal discontinuous Galerkin scheme 
    modg_space = 'Q',        -- the polynomial space Q or P
    m = 1,                   -- the maximal polynomial degree for each spatial direction
  },
  -- the temporal discretization scheme
  temporal = {
    name = 'explicitRungeKutta',  --'explicitEuler',
    steps = 4,
    -- how to control the timestep
    control = {
      name = 'cfl',   -- the name of the timestep control mechanism
      cfl  = 0.2,     -- Courant–Friedrichs–Lewy number
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
press = 1.0
velocityX = 1.0

function ic_gauss (x,y,z)
d= (x+1)*(x+1)+y*y+z*z 
return( dens + 1.0* math.exp(-d/0.02*math.log(2)) )
end 

initial_condition = {
 -- {
 -- predefined='gausspulse',
 -- center={-1., 0.0, 0.0},
 -- halfwidth=0.02,
 -- amplitude=2.0,
 -- background=dens
 --},

  --  {
  --     predefined='gausspulse',
  --     center={-1.0, 0.0, 0.0},
  --     halfwidth=0.2,
  --     amplitude=2.0,
  --     background=1.225
  --  },
  density = ic_gauss,
  velocityX = velocityX,
  velocityY = 0.0,
  velocityZ = 0.0,
  pressure = press, 
}

couplDens = dens 
couplMomX = dens * velocityX
couplMomY = 0.0
couplMomZ =0.0 
couplEnergy = (1/(equation.isen_coef -1)) * dens/press + 1/2 * velocityX*velocityX

 -- Boundary definitions
boundary_condition = {
  {
    label = 'west',
    kind = 'inflow',
    density = dens,
    velocityX = velocityX,
    velocityY = 0.0,
    velocityZ = 0.0
  }
  ,
  {
    label = 'east',
    kind = 'conservatives',
    density = 'couplDens', 
    momentumX = 'couplMomX',
    momentumY = 'couplMomY',
    momentumZ = 'couplMomZ',
    energy = 'couplEnergy',
  }
  ,
  {
    label = 'north',
    kind = 'outflow',
    pressure = press,
  }
  ,
  {
    label = 'south',
    kind = 'outflow',
    pressure = press,
  }
  ,
  {
    label = 'top',
    kind = 'outflow',
    pressure = press,
  }
  ,
  {
    label = 'bottom',
    kind = 'outflow',
    pressure = press,
  }

}
