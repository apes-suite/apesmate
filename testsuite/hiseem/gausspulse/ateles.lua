-- Configuration file for Ateles (Periodic Oscillator) --
require "common_aps"
require "seeder_atl"

eq_name = 'maxwell'
eq_name = 'maxwellDivCorrection'
--------------------------------------------------------------------------------
--...Configuration of simulation time
simulation_name = 'maxwell'  
sim_control = {
  time_control = { 
    --min = 0.0,
    --max = tmax_p,
    max = {iter=1000},
    interval = {iter=100}
    --interval = {iter=50}
  },
  abort_criteria = {
    steady_state = true,
    convergence = {
      variable = { 
        --'electric_field',
        'displacement_field'
      },
      shape = { 
        kind = 'all', 
        --object = {
        --  origin = {0.0,0.0,dx/2.0},
        --  --vec = {2*dx,0.0,0.0},
        --  --segments = {3}
        --}
      },
      time_control = {min=0, max=tmax_p, interval = {iter=10}},
      reduction = {'l2norm'},
      norm = 'average', nvals=100, absolute = true,
      ndofs = 1, use_get_point = false,
      condition = { threshold = '1e-8', operator = '<='}
    }
  }

}

NOdebug = {
  logging = {level=1, filename = 'dbg_atl', root_only = false}, 
}
logging = {level=5, 
        --   filename = 'log_atl'
}

--... Mesh definitions --
mesh = 'mesh_atl/'

--...Equation definitions --
variable = {
  {
    name = "var_current_density",
    ncomponents = 3,
    vartype = "st_fun",
    st_fun = currentDensitySpaceTime,
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
  name = eq_name,
  material = { 
    permeability = 'permeability',
    permittivity = 'permittivity',
    conductivity = 0.0,
    gam = 'gam',
    chi = 'chi'
  }
}
--------------------------------------------------------------------------------
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

-- ...Boundary condition
boundary_condition = {
  {
    label = 'north',
    kind = 'conservatives',
    displacement_fieldX = 0.0,           
    displacement_fieldY = permit*electric_field_external,
    displacement_fieldZ = 0.0,  
    magnetic_fieldX = 0.0,     
    magnetic_fieldY = 0.0,    
    magnetic_fieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = 0.0
  },
  {
    label = 'south',
    kind = 'conservatives',
    displacement_fieldX = 0.0,           
    displacement_fieldY = permit*electric_field_external,
    displacement_fieldZ = 0.0,  
    magnetic_fieldX = 0.0,     
    magnetic_fieldY = 0.0,    
    magnetic_fieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = 0.0
  },
  {
    label = 'east',
    kind = 'conservatives',
    displacement_fieldX = 0.0,           
    displacement_fieldY = permit*electric_field_external,
    displacement_fieldZ = 0.0,  
    magnetic_fieldX = 0.0,     
    magnetic_fieldY = 0.0,    
    magnetic_fieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = 0.0
  },
  {
    label = 'west',
    kind = 'conservatives',
    displacement_fieldX = 0.0,           
    displacement_fieldY = permit*electric_field_external,
    displacement_fieldZ = 0.0,  
    magnetic_fieldX = 0.0,     
    magnetic_fieldY = 0.0,    
    magnetic_fieldZ = 0.0,   
    magnetic_correction = 0.0, 
    electric_correction = 0.0
  },
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
    name = 'modg',  -- we use the modal discontinuous Galerkin scheme 
    m = 7,         -- the maximal polynomial degree for each spatial direction
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

ply_sampling = {nlevels=3}

 -- Tracking used for validation.    
tracking = {
  {
    label = 'vtk',
    folder = 'tracking_atl/',
    variable = {'displacement_field',
                'electric_field',
                'magnetic_field',
                'var_charge_density',
                'var_current_density'
    },
    shape = {kind = 'all'},
    --time_control={ min=0, max = tmax_p, interval = tmax_p/20},
    time_control={ min=0, max = tmax_p, interval = {iter=100}},
    --time_control={ min=0, max = tmax_p, interval = 2.9689361154796e-06},
    output = { format = 'vtk', use_get_point = false}
  },
  {
    label = 'point',
    folder = 'tracking_atl/',
    variable = {'displacement_field',
                --'electric_field',
                --'magnetic_field',
    },
    shape = {
      kind = 'all',
      --object = {
      --  origin = {0.0,0.0,dx/2.0}
      --}
    },
    reduction = {'l2norm'},--'average','average'},
    time_control={ min=0, max = tmax_p, interval = {iter=10}},
    output = { format = 'ascii', use_get_point = true}
  },
}

