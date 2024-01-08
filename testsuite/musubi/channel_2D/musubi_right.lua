----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository
                                                                          
--------------------------------------------------------------------!!!


-- Musubi configuration file. 

require "common"
inlet = 'ubb'
outlet = 'expol'
tracking_fol = 'tracking_right/'--prefix..subprefix..'tracking/'
restart_fol = 'restart_right/'

debug = {logging = {level=5, filename='dbg_right', root_only=false}}
logging = {level=10, filename = 'log_right'}
-- This is a LUA script.
--dx = getdxFromLevel( {len_bnd=length_bnd, level=level})
--dt = getdtFromVel( {dx = dx, u_p = u_in_phy, u_l = u_in_L } )
--omega = getOmegaFromdt( {dx=dx, dt=dt, nu_p = nu_phy } )

-- Simulation name
simulation_name = 'FlowAroundCyl'
mesh = 'mesh_right/' -- Mesh information
printRuntimeInfo = false
scaling = 'acoustic'
control_routine = 'fast'
io_buffer_size = 10 -- default is 80 MB

-- Time step settigs
interval = tmax/10
sim_control = {
  time_control = { 
    max = tmax,
    interval = interval
  } -- time control
} -- simulation control

-- restart 
estart = {
      ead = restart_fol..'channel2D_lastHeader.lua',
      write = restart_fol,
      time_control = { min = 0, max = tmax, interval = interval}
 }

logging = {level=10}
--debug = { logging = {level=1, filename='debug'},debugMode = true, debugFiles = true,
--          debugMesh = './debug/mesh_', debugStates = { 
--  write = {
--    folder    = './debug/',    -- the folder the restart files are written to
--    interval  = 1,           -- dump restart file interval
--    tmin      = 1,           -- first timestep to output
--    tmax      = tmax+1       -- last timestep to output
--    }
-- }
-- } 


-- needed to dump variable in physical unit
physics = { dt = dt, rho0 = rho0_p }

fluid = { omega = omega }

interpolation_method = 'linear'

-- Initial condition 
initial_condition = { pressure = p0_p, 
                      velocityX = 0.0,
                      velocityY = 0.0,
                      velocityZ = 0.0 }

identify = {label='2D',layout='d2q9',kind='lbm', relaxation = 'bgk'}
-- Boundary conditions
boundary_condition = {  
{ label = 'west', 
  --kind = 'inlet_'..inlet, 
  ----velocity = 'inlet_vel'
  --velocity = 'vel_cpl'
  kind = 'bc_pdf',
  pdf = 'pdf_cpl'
},
{ label = 'east',
--   kind = 'outlet_zero_prsgrd', 
--   kind = 'outlet_eq',
--   kind = 'outlet_pab',
--   kind = 'outlet_dnt',
   kind = 'outlet_'..outlet,
   pressure = 'p0' }, 
{ label = 'north', 
   kind = 'wall' },
{ label = 'south', 
   kind = 'wall' },
{ label = 'sphere', 
   kind = 'wall' }
 }
-- user variables
variable = {
 --{
 --   name = 'vel_cpl',
 --   ncomponents = 3,
 --   vartype = 'st_fun',
 --   st_fun = { 
 --     predefined = 'apesmate',
 --     domain_from = 'dom_left',
 --     input_varname = {'velocity_phy'}
 --   }
 --},
 {
    name = 'pdf_cpl',
    ncomponents = 9,
    vartype = 'st_fun',
    st_fun = { 
      predefined = 'apesmate',
      domain_from = 'dom_left',
      input_varname = {'fetch_pdf'}
    }
  },
  {
    name = 'p0',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = p0_p, 
  },
}

-- Tracking
tracking = {
--{
--  label = 'probe_pressure', 
--  folder = tracking_fol,
--  variable = {'pressure_phy'}, 
--  shape = {
--          {kind = 'canoND', object = {origin ={0.15-dx,0.2,zpos} }},
--          {kind = 'canoND', object = {origin ={0.25+dx,0.2,zpos} }}
--          },
--  time_control = {min = 0, max = tmax, interval = 10*dt},
--  output={format = 'ascii'}
--},
 { -- GLobal VTK
   label = 'global', 
   folder = tracking_fol,
   variable = {'velocity_phy', 'pressure_phy','pdf'},
   shape = {
     {kind = 'all',}
   },
   time_control = {min = 0, max = tmax, interval = tmax/100},
   output={format = 'vtk'},
 },
--{
--  label = 'force', 
--  folder = tracking_fol,
--  variable = {'bnd_force_phy','bnd_force'}, 
--  shape = { kind = 'boundary', boundary = {'sphere'}},
--  time_control = {min = tmax, max = tmax, interval = tmax},
--  reduction = {'sum','sum'},
--  output={format = 'ascii'}      
--},
--{
--  label = 'hvs_force', 
--  folder = tracking_fol,
--  variable = {'bnd_force_phy'}, 
--  shape = { kind = 'boundary', boundary = {'sphere'}},
--  time_control = {min = tmax, max = tmax, interval = tmax},
--  output={format = 'harvester'}      
--},

--{
--  label = 'probe_velocity', 
--  folder = tracking_fol,
--  variable = {'velocity_phy'}, 
--  shape = {
--           {kind = 'canoND', object = {origin = {length*0.5,0.2,zpos}}}},
--  time_control = {min = 0, max = tmax, interval = 10*dt},
--  output={format = 'ascii'}      
--},
--{
--  label = 'line_velocity_in', 
--  folder = tracking_fol,
--  variable = {'velocity_phy'}, 
--  shape = {kind = 'canoND', object = {origin = {dx_half,0.0,zpos},
--                                     vec = {0.0,height,0.0},
--                                     segments = nHeight+2}},
--  time_control = {min = tmax, max = tmax, interval = tmax},
--  output={format = 'asciiSpatial'}      
--},
--{
--  label = 'line_velocity_inmean', 
--  folder = tracking_fol,
--  variable = {'velocity_phy'}, 
--  shape = {kind = 'canoND', object = {origin = {0.1/2.0,0.0,zpos},
--                                     vec = {0.0,height,0.0},
--                                     segments = nHeight+2}},
--  reduction = 'average',                                   
--  time_control = {min = 0, max = tmax, interval = tmax},
--  output={format = 'asciiSpatial'}      
--},
--
--{
--  label = 'line_velocity_middle', 
--  folder = tracking_fol,
--  variable = {'velocity_phy'}, 
--  shape = {kind = 'canoND', object = {origin = {length*0.5,0.0,zpos},
--                                     vec = {0.0,height,0.0},
--                                     segments = nHeight+2 }},
--  time_control = {min = tmax, max = tmax, interval = tmax},
--  output={format = 'asciiSpatial'}      
--},
--
--{
--  label = 'line', 
--  folder = tracking_fol,
--  variable = {'pressure_phy','velocity_phy'}, 
--  shape = {kind = 'canoND', object = {origin = {0.0,0.2,zpos},
--                                     vec = { length, 0.0,0.0},
--                                     segments = nLength+2}
--                                         },
--  time_control = {min = tmax, max = tmax, interval = tmax},
--  output={format = 'asciiSpatial'}      
--}

}

