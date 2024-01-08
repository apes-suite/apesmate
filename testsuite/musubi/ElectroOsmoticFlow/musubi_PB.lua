----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository
                                                                          
--------------------------------------------------------------------!!!
-- Musubi configuration file. 
require "common"

-- Time step
scaling = 'diffusive'
dt =dx*dx
--print(dt)

tracking_fol = 'tracking_PB/'
restart_fol = 'restart_PB/'

-- Simulation name
simulation_name = 'PB'
mesh = 'mesh/' -- Mesh information
printRuntimeInfo = false

control_routine = 'fast'
io_buffer_size = 10 -- default is 80 MB
logging = { level=5, filename = 'log_PB'}

tmax = 1000000
-- Time step settigs
sim_control = {
  time_control = { 
    max = {iter=tmax},
    interval = {iter=500}
  } -- time control
 ,abort_criteria = {
    steady_state = true,
    convergence = {
      variable = {'potential_phy'}, 
      shape = {
        kind = 'canoND', 
        object = {
          origin ={length/2.0,-dx,zpos},
          vec = {0.0,height+2*dx,0.0},
          segments = nLength+2
        }
      },
      time_control = {min = 0, max = {iter=tmax}, interval = {iter=1}},
      reduction = 'average',
      norm='average', nvals = 1, absolute = true,
      condition = { threshold = 1.e-10, operator = '<=' }
    }
  }
} -- simulation control

-- restart 
restart = {
  read = restart_fol..'PB_lastHeader.lua',
  write = restart_fol,
}

-- needed to dump variable in physical unit
physics = { dt = dt, rho0=1000.0, temp0=273.0 }

poisson = { 
  potential_diffusivity = 0.3, 
  permittivity=permit, 
  poisson_boltzmann = {
    moleDens0 = moleDens0,
    temp = temp, 
    valence={1.0,-1.0}, 
  }  
}

-- Initial condition 
initial_condition = { potential = ref_pot }

identify = {
  layout='d2q5',
  kind='poisson_boltzmann_nonlinear', 
  relaxation = 'bgk'
}

-- Boundary conditions
boundary_condition = {  
{ label = 'north', 
   kind = 'potential_dirichlet',
   potential = ref_pot},
{ label = 'south', 
   kind = 'potential_dirichlet',
   potential = ref_pot},
}


variable = {
  {
    name = 'analy_pot',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = analy_pot
  },
  {
    name = 'error',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'difference',
      input_varname = {'potential_phy','analy_pot'}
    }
  },
  {
    name = 'ext_electric_field',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'combined',
      spatial = {500,0.0,0.0}
    }  
  },
--  {
--    name = 'tot_electric_field',
--    ncomponents = 3,
--    vartype = 'operation',
--    operation = {
--      kind = 'addition',
--      input_varname = {'electric_field_phy','ext_electric_field'}
--    }
--  },
  {
    name = 'ext_force',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'multiply_scalar_times_vector',
      input_varname = {'charge_density_phy', 'ext_electric_field'}
    }
  }
}

-- Tracking
NOtracking = {
  {
    label = 'vtk', 
    folder = tracking_fol,
    variable = {'potential_phy','electric_field_phy', 'charge_density_phy',
                'tot_electric_field', 'ext_force'}, 
    NOvariable = {'potential_phy','electric_field_phy'}, 
    shape = {
            kind = 'all'
    },
    --time_control = {min = {iter=10000}, max = {iter=10000}, interval = {iter=10000}},
    time_control = {min = {iter=10000}, max = {iter=10000}, interval = {iter=10000}},
    output={format = 'vtk'}
  },
  {
    label = 'line', 
    folder = tracking_fol,
    variable = {'potential_phy','analy_pot','error','electric_field_phy', 'charge_density_phy'}, 
    shape = {
      kind = 'canoND', 
      object = {
        origin ={length/2.0,-dx,zpos},
        vec = {0.0,height+2*dx,0.0},
        segments = nLength+2
      }
    },
    time_control = {min = {iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}},
    output={format = 'asciiSpatial'}
  },
}

