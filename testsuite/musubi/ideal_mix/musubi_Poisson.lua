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

bc_pot = 'potential_dirichlet'
bc_pot_north = 'potential_neumann'
bc_pot_south = 'potential_neumann'
bc_pot_north = 'potential_dirichlet'
bc_pot_south = 'potential_dirichlet'

tracking_fol = 'tracking_Pot/'
restart_fol = 'restart_Pot/'
timing_file = 'timing_Pot.res'

-- Simulation name
simulation_name = 'Pot'
mesh = 'mesh/' -- Mesh information
printRuntimeInfo = true

control_routine = 'fast'
io_buffer_size = 10 -- default is 80 MB
logging = { level=5, filename = 'log_Pot'}

tmax = 1e8
-- Time step settigs
sim_control = {
  time_control = { 
    max = {iter=tmax},
    interval = {iter=5000},
    check_iter=1
  } -- time control
 ,abort_criteria = {
    steady_state = true,
    convergence = {
      variable = {'potential_phy'}, 
      --variable = {'ef_mag'}, 
      shape = {
        kind = 'canoND', 
        object = {
          --origin ={length/2.0,dx/2.0,zpos},
          origin ={length/2.0,-dx-offset,zpos},
          vec = {0.0,height+2*dx,0.0},
          segments = nHeight+2
        }
      },
      time_control = {min = 0, max = {iter=tmax}, interval = {iter=25}},
      reduction = 'l2norm',
      norm='average', nvals = 50, absolute = false,
      condition = { threshold = 1.e-6, operator = '<=' }
    }
  }
} -- simulation control

-- restart 
restart = {
  NOread = restart_fol..'Pot_lastHeader.lua',
  write = restart_fol,
}

-- needed to dump variable in physical unit
physics = { dt = dt, rho0=rho0_p, temp0=temp }

poisson = { 
  potential_diffusivity = 0.167, 
  permittivity=permit, 
}

function IC_pot(x,y,z)
  return -y/(height/2.0)*ref_pot
  --if y>=height/2.0 then
  --  return (y-height/2.0)/(height/2.0)*ref_pot
  --else
  --  return (height/2.0-y)/(height/2.0)*ref_pot
  --end
end
-- Initial condition 
initial_condition = { 
  --potential = IC_pot,
  potential = 0.0--ref_pot
  --potential = analy_pot
}

identify = {
  layout='d2q9',
  kind='poisson', 
  relaxation = 'bgk'
}

-- Boundary conditions
boundary_condition = {  
 { 
   label = 'north', 
   kind = bc_pot_north,
   potential = pot_north,
   surface_charge_density = charge_north
 },
 { 
   label = 'south', 
   kind = bc_pot_south, 
   potential = pot_south,
   surface_charge_density = charge_south
 },
}


variable = {
  {
    name = 'analy_pot',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = analy_pot
  },
  {
    name = 'analy_electric_field',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = analy_electric_field
  },
  {
    name = 'analy_charge_dens',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = analy_charge_density
  },
  {
    name = 'ef_mag',
    ncomponents = 1,
    vartype = 'operation',
    operation = {
      kind = 'magnitude',
      input_varname = {'electric_field_phy'}
    }
  },
  {
    name = 'cpl_charge_dens',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_MS',
      input_varname = {'charge_density_phy'}
    }
  }
}

glob_source = {charge_density = 'cpl_charge_dens'}
-- Tracking
NOtracking = {
--  {
--    label = 'vtk', 
--    folder = tracking_fol,
--    variable = {'potential_phy','electric_field_phy'}, 
--    shape = {
--            kind = 'all'
--    },
--    --time_control = {min = {iter=10000}, max = {iter=10000}, interval = {iter=10000}},
--    time_control = {min = {iter=0}, max = {iter=tmax}, interval = {iter=1}},
--    output={format = 'vtk'}
--  },
  {
    label = 'line', 
    folder = tracking_fol,
    variable = {'potential_phy','electric_field_phy'}, 
    shape = {
      kind = 'canoND', 
      object = {
        origin ={dx/2.0,-dx-offset,zpos},
        vec = {0.0,height+2*dx,0.0},
        segments = nHeight+2
      }
    },
    time_control = {min = {iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}},
    output={format = 'asciiSpatial'}
  },
  {
    label = 'probe_south', 
    folder = tracking_fol,
    variable = {'potential_phy','electric_field_phy'}, 
    shape = {
      kind = 'canoND', 
      object = {
        origin ={length/2.0,dx/2.0-offset,zpos},
      }
    },
    time_control = {min = {iter=0}, max = {iter=tmax}, interval = {iter=100}},
    output={format = 'ascii'}
  },
  {
    label = 'probe_center', 
    folder = tracking_fol,
    variable = {'potential_phy','electric_field_phy'}, 
    shape = {
      kind = 'canoND', 
      object = {
        origin ={length/2.0,height/2.0-offset,zpos},
      }
    },
    time_control = {min = {iter=0}, max = {iter=tmax}, interval = {iter=100}},
    output={format = 'ascii'}
  },
  {
    label = 'probe_l2norm', 
    folder = tracking_fol,
    variable = {'potential_phy','electric_field_phy'}, 
    shape = {
      kind = 'canoND', 
      object = {
          origin ={length/2.0,-dx-offset,zpos},
          vec = {0.0,height+2*dx,0.0},
          segments = nHeight+2
      }
    },
    reduction = {'l2norm', 'l2norm'},
    time_control = {min = {iter=0}, max = {iter=tmax}, interval = {iter=100}},
    output={format = 'ascii'}
  }
}

