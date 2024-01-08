----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository
                                                                          
--------------------------------------------------------------------!!!
-- Musubi configuration file. 
require "common"

scaling = 'diffusive'
omega = 1.0/1.7
nu_L = (1.0/omega-0.5)/3.0
dt = nu_L*dx^2/nu_phy
press_p = rho0_p*dx^2/dt^2
p0_p = press_p
--print(dt)

tracking_fol = 'tracking_fluid/'
restart_fol = 'restart_fluid/'

NOdebug = {logging = {level=1, filename='dbg_fluid', root_only=false}}
logging = {level=5, filename = 'log_fluid'}
-- This is a LUA script.
--dx = getdxFromLevel( {len_bnd=length_bnd, level=level})
--dt = getdtFromVel( {dx = dx, u_p = u_in_phy, u_l = u_in_L } )
--omega = getOmegaFromdt( {dx=dx, dt=dt, nu_p = nu_phy } )

-- Simulation name
simulation_name = 'EOF'
mesh = 'mesh/' -- Mesh information
printRuntimeInfo = false
control_routine = 'fast'
io_buffer_size = 10 -- default is 80 MB

-- Time step settigs
tmax = 1e-6 --sec
interval = tmax/10
sim_control = {
  time_control = { 
    max = tmax,
    interval = interval
  } -- time control
 ,abort_criteria = {
    steady_state = false,
    convergence = {
      variable = {'velocity_phy'}, 
      shape = {
        kind = 'all',
      },
      time_control = {min = 0, max = tmax, interval = {iter=10}},
      reduction = 'average',
      norm='average', nvals = 50, absolute = true,
      condition = { threshold = 1.e-10, operator = '<=' }
    }
  }
} -- simulation control

-- restart 
restart = {
  read = restart_fol..'EOF_lastHeader.lua',
  write = restart_fol,
  --time_control = { min = tmax, max = tmax, interval = tmax}
 }

-- needed to dump variable in physical unit
physics = { dt = dt, rho0 = rho0_p }

fluid = { omega = omega }

interpolation_method = 'linear'

-- Initial condition 
initial_condition = { pressure = p0_p, 
                      velocityX = 0.0,
                      velocityY = 0.0,
                      velocityZ = 0.0 }

identify = {label='2D',layout='d2q9',kind='lbm_incomp', relaxation = 'bgk'}
-- Boundary conditions
boundary_condition = {  
  { label = 'north', 
     kind = 'wall' },
  { label = 'south', 
     kind = 'wall' },
}

glob_source = {
  force_explicit = 'electric_force'
}
-- user variables
variable = {
  {
    name = 'electric_force',
    ncomponents = 3,
    vartype = 'st_fun',
    NOst_fun = {1e8,0.0,0.0},
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_pb',
      input_varname = {'ext_force'},
    }   
  },
}

-- Tracking
tracking = {
  { -- GLobal VTK
    label = 'vtk', 
    folder = tracking_fol,
    variable = {'velocity_phy', 'velocity'},
    shape = {
      {kind = 'all',}
    },
    time_control = {min = 0, max = tmax, interval = {iter=100}},
    output={format = 'vtk'},
  },
--  {
--    label = 'line', 
--    folder = tracking_fol,
--    variable = {'velocity_phy'}, 
--    shape = {
--      kind = 'canoND', 
--      object = {
--        origin ={length/2.0,-dx,zpos},
--        vec = {0.0,height+2*dx,0.0},
--        segments = nLength+2
--      }
--    },
--    time_control = {min = {iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}},
--    output={format = 'asciiSpatial'}
--  },
--  {
--    label = 'probe', 
--    folder = tracking_fol,
--    variable = {'velocity_phy'}, 
--    shape = {
--      kind = 'canoND', 
--      object = {
--        origin ={length/2.0, height/2.0,zpos},
--      }
--    },
--    time_control = {min = {iter=0}, max = {iter=tmax}, interval = {iter=10}},
--    output={format = 'ascii'}
--  },
}

