-- Configuration file for Ateles (Periodic Oscillator) --
require "common"

--------------------------------------------------------------------------------
--...Configuration of simulation time
simulation_name = 'maxwell_source'  
--debug = {logging = {level=1, filename='dbg_atl', root_only=false}}
--logging = { level=5, filename = 'log_atl'}
sim_control = {
  time_control = { 
    --max = tmax_p, -- Number of iterations / Simulated time
    --min = 0.0,
    --interval = {iter=10}
    max = {iter=1000},
    interval = {iter=50}
  }
}

--... Mesh definitions --
mesh = 'mesh_atl/'

-- Material info
permea_0 = 1.2566e-6 --N/A-2 permeability of vaccum
rel_permea_water = 0.99 
permea = permea_0 * rel_permea_water
permit_0 = 8.854e-12 -- F/m or C/(Vm)Permittivity of vaccum
rel_permit_water = 80
permit = permit_0 * rel_permit_water
gam = 1.0
chi = 1.0

-- Source term definition, i.e. in Maxwell equations we are talking about 
-- space charges and 

-- Source term
-- ... charge of the source 
Q = 1.0e+5
-- ... radius of sphere source
r = height/8 
-- ... parameters for the analytic solution
freq = ( 2.0*math.pi/math.sqrt(permit*permea) ) *10
-- ... the temporal period of the waveguide
T = 2.0*math.pi/freq

-- current densities. In general they can depend on spatial coordinates and time.
function currentDensitySpaceTime(x, y, z, t)
  --d = math.sqrt((x-length/2.0)^2.0+(y-height/2.0)^2.0)
  --if d <= r then
  --  jx=Q*r*freq*math.sin(freq*t)
  --  jy=Q*r*freq*math.sin(freq*t)
  --  jz=Q*r*freq*math.sin(freq*t)
  --  --return {jx,jy,jz}
  --  return {jx,0.0,0.0}
  --  --return {1.0,1.0,0.0}
  --else
  --  return {0.0, 0.0, 0.0}
  --end
  --return {1e5*x/height,1e5*y/height,0.0}
  return {0.0, 0.0, 0.0}
end

function chargeDensitySpaceTime(x,y,z,t)
  --d = math.sqrt((x-length/2.0)^2.0+(y-height/2.0)^2.0)
  --if d <= r then
  --  return Q
  --else
  --  return 0.0
  --end
  --if (y>height/2.0) then
  --  return Q*y/(height*0.5)
  --else
  --  return -Q*(1-y/(height*0.5))
  --end 
  return 0.0
end

function currentDensity_vel(x,y,z,t)
  return {Q*4.0*u_max_phy*y*(height-y)/height^2.0,0.0,0.0}
end

--...Equation definitions --

variable = {
  {
    name = "var_current_density",
    ncomponents = 3,
    vartype = "st_fun",
    st_fun = currentDensity_vel,
  },
  {
    name = "var_charge_density",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = chargeDensitySpaceTime,
  },
  {
    name = "var_current_density_cpl",
    ncomponents = 3,
    vartype = "st_fun",
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_musubi',
      input_varname = {'current_density_phy'}
    }
  },
  {
    name = "var_charge_density_cpl",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_musubi',
      input_varname = {'charge_density_phy'}
    }   
  },

  -- This is the global material for Maxwell. It consists of two different 
  -- components, permittivity, and conductivity.
  -- As this is the global fallback material, we define each material to be a 
  -- neutral term, which in this case is 0.
  {
    name = "permeability",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      const = { permea }
    }
  },
  {
    name = "permittivity",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      const = { permit }
    }
  },
  {
    name = "gam",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      const = { gam }
    }
  },
  {
    name = "chi",
    ncomponents = 1,
    vartype = "st_fun",
    st_fun = {
      const = { chi }
    }
  },
  {
    name = 'electric_field',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'divide_vector_by_scalar',
      input_varname = {'displacement_field', 'permittivity'}
    }
  }
}

source = {
  currentDensity = 'var_current_density',
  charge = 'var_charge_density'
}

equation = {
  -- we solve maxwell’s equations with divergence correction
  name = 'maxwellDivCorrection',
  material = { 
    permeability = 'permeability',
    permittivity = 'permittivity',
    gam = 'gam',
    chi = 'chi'
  }
}
--------------------------------------------------------------------------------
---- ...the initial condition table. 
---- ...initial condition function for displacement field (z component)
--function ic_displacementZ(x,y,z)
--  return displacementZ(x,y,z,0.0)
--end
 
-- ...Initial condition
initial_condition = {
  displacement_fieldX = 0.0,           
  displacement_fieldY = permit*electric_field_external,
  displacement_fieldZ = 0.0,  
  magnetic_fieldX = 0.0,     
  magnetic_fieldY = 0.0,    
  magnetic_fieldZ = 0.0,   
  magnetic_correction = 0.0, 
  electric_correction = 0.0--electric_fieldY,
}

--... Definition of the projection method
projection = {
  kind = 'fpt',  -- 'fpt' or 'l2p', default 'l2p'
                 -- for fpt the  nodes are automatically 'chebyshev'
                 -- for lep the  nodes are automatically 'gauss-legendre'
  -- lobattoPoints = false  -- if lobatto points should be used, default = false
  factor = 1.0          -- dealising factpr for fpt, oversampling factor for l2p, float, default 1.0
  -- blocksize = 32,        -- for fpt, default -1
  -- fftMultiThread = false -- for fpt, logical, default false
}

--... Scheme definitions --
scheme = {
  -- the spatial discretization scheme
  spatial =  {
    name = 'modg',           -- we use the modal discontinuous Galerkin scheme 
    m = 7,                   -- the maximal polynomial degree for each spatial direction
    modg_space = 'Q'
  },
  -- the temporal discretization scheme
  temporal = {
    name = 'explicitRungeKutta', --'explicitEuler',
    steps = 4,
    -- how to control the timestep
    control = {
      name = 'cfl',   -- the name of the timestep control mechanism
      cfl  = 0.95     -- CourantÐFriedrichsÐLewy number
    }
  }
}

--...Configuration for the restart file
restart = { 
  write = 'restart_atl/',
  NOread = 'restart_atl/maxwell_source_lastHeader.lua',
  -- temporal definition of restart write
  time_control = {
    min = tmax_p,
    max = tmax_p,
    --interval = tmax_p/5.0
  }
}

ply_sampling = {nlevels=2}

 -- Tracking used for validation.    
tracking = {
  {
    label = 'vtk',
    folder = 'tracking_atl/',
    variable = {'displacement_field',
                'magnetic_field',
                'permittivity',
                'permeability',
                'electric_correction',
                'magnetic_correction',
                'var_charge_density',
                'var_current_density'
    },
    shape = {kind = 'all'},
    --time_control={ min=0, max = tmax_p, interval = tmax_p/50},
    time_control={ min=0, max = tmax_p, interval = {iter=100}},
    output = { format = 'vtk', use_get_point = false}
  },
}


-- Boundary definitions
NOboundary_condition = {
  {
    label = 'west',   
    kind = 'pec'
  },
  {
    label = 'east',   
    kind = 'pec'
  },
  {
    label = 'north',   
    kind = 'pec'
  },
  {
    label = 'south',   
    kind = 'pec'
  },
}
boundary_condition = {
  {
    label = 'west',   
    kind = 'conservatives',
    displacementFieldX = 0.0,           
    displacementFieldY = initial_condition.displacement_fieldY,
    displacementFieldZ = 0.0,  
    magneticFieldX = 0.0,     
    magneticFieldY = 0.0,    
    magneticFieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = initial_condition.electric_correction,
  },
  {
    label = 'east',   
    kind = 'conservatives',
    displacementFieldX = 0.0,           
    displacementFieldY = initial_condition.displacement_fieldY,
    displacementFieldZ = 0.0,  
    magneticFieldX = 0.0,     
    magneticFieldY = 0.0,    
    magneticFieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = initial_condition.electric_correction,
  },
  {
    label = 'north',   
    kind = 'conservatives',
    displacementFieldX = 0.0,           
    displacementFieldY = initial_condition.displacement_fieldY,
    displacementFieldZ = 0.0,  
    magneticFieldX = 0.0,     
    magneticFieldY = 0.0,    
    magneticFieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = initial_condition.electric_correction,
  },
  {
    label = 'south',   
    kind = 'conservatives',
    displacementFieldX = 0.0,           
    displacementFieldY = initial_condition.displacement_fieldY,
    displacementFieldZ = 0.0,  
    magneticFieldX = 0.0,     
    magneticFieldY = 0.0,    
    magneticFieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = initial_condition.electric_correction,
  },
}
