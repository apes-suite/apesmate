-- Musubi configuration file. 
-- This is a LUA script.

require 'seeder_right'

-- Mesh information
mesh = 'mesh_right/'

identify = {
            kind = 'lbm',
            relaxation = 'bgk',
            layout = 'd3q19'
           }
fluid = { omega = 1.8, rho0 = 1.0 }

-- Simulation name
simulation_name = identify.relaxation .. '-' .. commpattern

-- Initial Case
initial_condition = { 
   pressure  = ic_1Dgauss_pulse, -- see above for its definition / computation.
   velocityX = 0.0,
   velocityY = 0.0,
   velocityZ = 0.0
}

interpolation_method = 'linear'                     

-- Boundary conditions
boundary_condition = {  
  { label = 'west', 
    kind = 'inlet_ubb', 
    --velocity = 'inlet_vel'
    velocity = 'vel_cpl'
  },
  { label = 'east',
  --   kind = 'outlet_zero_prsgrd', 
  --   kind = 'outlet_eq',
  --   kind = 'outlet_pab',
  --   kind = 'outlet_dnt',
     kind = 'outlet_expol',
     pressure = 'p0' 
     --pressure = 'press_cpl' 
  }, 
}
-- user variables
variable = {
  --{
  --  name = 'vel_x',
  --  ncomponents = 1,
  --  vartype = 'st_fun',
  --  st_fun = 0.0
  --},
  --{
  --  name = 'vel_y',
  --  ncomponents = 1,
  --  vartype = 'st_fun',
  --  st_fun = 0.0
  --},
  --{
  --  name = 'vel_z',
  --  ncomponents = 1,
  --  vartype = 'st_fun',
  --  st_fun = 0.0
  --},
  --{
  --  name = 'inlet_vel',
  --  ncomponents = 3,
  --  vartype = 'operation',
  --  operation = {
  --    kind = 'combine',
  --    input_varname = {'vel_x','vel_y','vel_z'}
  --  }  
  --},
  --{
  --  name = 'press_cpl',
  --  ncomponents = 1,
  --  vartype = 'st_fun',
  --  st_fun = { 
  --    predefined = 'apesmate',
  --    domain_from = 'dom_right',
  --    input_varname = {'pressure_phy'}
  --  }   
  --},
  {
    name = 'vel_cpl',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_left',
      input_varname = {'velocity_phy'}
    }
  },
  {
    name = 'p0',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = p0, 
  },
}
-- Time step settings
--nprocs = os.getenv('nprocs')
nprocs = 6
-- total number of iterations
tmax           = math.min(((8^ 9)*nprocs) / (8^level), 10)
time = {useIterations = true, -- Timings given in iterations? default: true
        max = tmax,           -- Maximal iteration to reach
        interval = tmax,     -- Interval for checking density
        min = 1 }              -- Minimal timestep to start from

-- Ramping settings  
ramping        = false

-- Output settings
output = { active = false,
           vtk = true,     -- VTK output activated?
           interval = -1,        -- output interval 
           tmin = 0,         -- first iteration to output
           tmax = 0 } 
-- Restart settings
restart = {
  -- If this table is available it will write a restart file
  -- with the specified options.
--  write = {
--    folder    = 'restart/', -- the folder the restart files are written to
--    interval  = 1,                                     -- dump restart file interval
--    tmin      = tmax+1,                                   -- first timestep to output
--    tmax      = tmax+1                                    -- last timestep to output
--    }
  }
