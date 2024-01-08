-- load lua variables from simParam.lua
require "common"

tracking_fol = 'tracking_mus/'
scheme_kind = 'bgk'

bc_inlet = 'spc_molefrac_eq'
bc_inlet = 'spc_inlet_eq'

bc_outlet = 'spc_vel_bb'
bc_outlet = 'spc_outlet_vel'
bc_outlet = 'spc_outlet_eq'

bc_mem = 'spc_blackbox_mem_ion'
bc_mem = 'wall'

-- simulation paramters
io_buffer_size = 1
printRuntimeInfo = true

---- communication pattern
--isend_irecv_overlap gathered_type isend_irecv typed_isend_irecv
commpattern = 'isend_irecv'
control_routine = 'fast'
-- Simulation name
simulation_name = 'taylorDispersion'
mesh = 'mesh_mus/'

-- Interpolation method
-- average, copyfirst, linear, debug
interpolation_method = 'average'                   
scaling = 'diffusive'
NOdebug = {logging = {level=1, filename='dbg_mus', root_only=false}}
logging = { level=5, 
            --filename = 'log_mus'
}

-- Time step settings
interval = tmax_p/100
sim_control = {
  time_control = {
    max = tmax_p, 
    interval = interval,
    check_iter = 10
  }
  --time_control = {
  --  max = {iter=100}, 
  --  interval = {iter=10} 
  --}
}

-- restart
restart = {
  --read = 'restart/taylorDispersion_header_25.004E-03.lua',
  NOread = 'restart_mus/taylorDispersion_lastHeader.lua',
  write = 'restart_mus/',
  time_control = { min = tmax_p, max = tmax_p, interval = tmax_p}
}

physics = { rho0 = rho0_p, 
            dt = dt, 
            --molWeight0 = m_min, 
            temp0 = 273.0,
            --moleDens0 = moleDens0,
            --coulomb0 = 1.0
}

-- scheme model for single fluid simulation
identify = {
    kind = 'multi-species_liquid', 
    relaxation = scheme_kind, 
-- scheme layout
    layout = 'd3q19'
}

NOglob_source = { electric_field = 'electric' }

mixture = { rho0 = rho0_p, moleDens0 = moleDens0,
            omega_diff = omega_diff,
            --kine_shear_viscosity = nu_phy,
            --bulk_viscosity = 1e-7,
            omega_kine = 2.0,
            omega_hom = 0.1,
            theta_eq = 1.0,
            temp = 293.15,
	    prop_file = 'H2O_NaCl.dat',
            electricField = { 0.0, 1e-10, 0.0},
            --gravityField = { deltaP/rho0_p,0.0,0.0},
            initial_condition = { pressure = 0.0}--TGV_kinematicPressure }
          }

-- user variables
variable = {
  {
    name = 'bc_vel',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = velocity
  },
  { 
    name = 'mf_inlet_H2O',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = BC_H2O 
  },
  { 
    name = 'mf_inlet_Na',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = BC_Na 
  },
  { 
    name = 'mf_inlet_Cl',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = BC_Cl 
  },
  { 
    name = 'outlet_press',
    ncomponents = 1,
    vartype = 'st_fun',
    st_fun = 0.0 
  },
  { name = 'electric',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = electric_force--{0.0,1e-9,0.0}
  },
  {
    name = 'electric_cpl',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = {
      predefined = 'apesmate',
      domain_from = 'dom_ateles',
      input_varname = {'electric_field'}
    }
  }
}
-- field which defines fluid or specie
-- Single fluid simulation
field = {{
  label = 'H2O'
-- species properties
   ,species = { molweight = mH2O, 
                diff_coeff = { diff_diag, diff_H2O_Na, diff_H2O_Cl },
                charge_nr = charge_nr_H2O}
-- Initial condition
   ,initial_condition = { 
      mole_fraction = IC_H2O,
      velocityX = IC_velocity,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     {
       label = 'west',
       kind = bc_inlet,
       mole_fraction = 'mf_inlet_H2O',
       velocity = 'bc_vel',
       --order = 2
     },
     {
       label = 'east',
       kind = bc_outlet,
       velocity = 'bc_vel',
       pressure = 'outlet_press'
     },
     { label = 'north', kind = 'wall'},
     { label = 'south', kind = 'wall'},
--     {
--       label = 'sphere',
--       kind = 'wall_libb'
--     }
    }
  }
 ,{
    label = 'Na'
   ,species = { molweight = mNa, 
                diff_coeff = { diff_H2O_Na, diff_diag, diff_Na_Cl },
                charge_nr = charge_nr_Na}
   ,initial_condition = {
      mole_fraction = IC_Na,
      velocityX = IC_velocity,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     {
       label = 'west',
       kind = bc_inlet,
       mole_fraction = 'mf_inlet_Na',
       velocity = 'bc_vel',
       --order = 2
     },
     {
       label = 'east',
       kind = bc_outlet,
       velocity = 'bc_vel',
       pressure = 'outlet_press'
     },
     { label = 'north', 
       kind = bc_mem,
       transference_number = 0.971 
     },
     { label = 'south', 
       kind = bc_mem,
       transference_number = (1.0-0.998)
     },
--     {
--       label = 'sphere',
--       kind = 'wall_libb'
--     }
    }
  }
 ,{
    label = 'Cl'
   ,species = { molweight = mCl, 
                diff_coeff = { diff_H2O_Cl, diff_Na_Cl, diff_diag },
                charge_nr = charge_nr_Cl}
   ,initial_condition = {
      mole_fraction = IC_Cl,
      velocityX = IC_velocity,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     {
       label = 'west',
       kind = bc_inlet,
       mole_fraction = 'mf_inlet_Cl',
       velocity = 'bc_vel',
       --order = 2
     },
     {
       label = 'east',
       kind =  bc_outlet,
       velocity = 'bc_vel',
       pressure = 'outlet_press'
     },
     { label = 'north', 
       kind = bc_mem,
       transference_number = (1.0-0.971) 
     },
     { label = 'south', 
       kind = bc_mem,
       transference_number = 0.998 },
--     {
--       label = 'sphere',
--       kind = 'wall_libb'
--     }
    }
  }
}
tracking = {
  {
    label = 'vtk',
    variable = {
                'vel_mag_phy', 'H2O_mole_density_phy', 
                'Na_mole_density_phy', 'Cl_mole_density_phy',
                'velocity_phy', 'H2O_mole_fraction', 
                'Na_mole_fraction', 'Cl_mole_fraction',
                'charge_density_phy', 'current_density_phy'
                },
    folder=tracking_fol,
    shape = {kind='all'},
    output={format='vtk'},
    time_control={ min=0, max = tmax_p, interval = tmax_p/50}
    --time_control={ min=0, max = tmax_p, interval = {iter=10}}
  },
--  {
--    label = 'moleDensity',
--    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy'},
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {0.0,height/2.0,dx/2.},
--                                       vec = {length,0.0,0.0},
--                                       segments = nLength+2}
--            },
--    reduction = {'average','average','average'},        
--    output={format='ascii'},
--    time_control={ min=0, max = tmax_p, interval = {iter=100}}
--  },

--  {
--    label = 'inlet_velMax',
--    variable = {
--                'vel_mag_phy',
--                },
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {dx/2.,height/2.0,dx/2.}}
--            },
--    output={format='ascii'},
--    time_control={ min=0, max = tmax_p, interval = dt}
--  }
--  ,
--  {
--    label = 'inlet_numDens',
--    variable = {'H2O_mole_density_phy','Na_mole_density_phy','Cl_mole_density_phy',
--                'mole_density_phy',
--                'velocity_phy',
--                'H2O_mole_flux_phy','Na_mole_flux_phy','Cl_mole_flux_phy'},
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {dx/2.,0.0,dx/2.},
--                                       vec = {0.0,height,0.0},
--                                       segments = nHeight+2}
--            },
--    output={format='ascii'},
--    reduction={'average','average','average','average','average','average','average','average'},
--    time_control={ min=0, max = tmax_p, interval = tmax_p/tmax}
--  }
--  ,
--  {
--    label = 'outlet_numDens',
--    variable = {'H2O_mole_density_phy','Na_mole_density_phy','Cl_mole_density_phy',
--                'mole_density_phy',
--                'velocity_phy',
--                'H2O_mole_flux_phy','Na_mole_flux_phy','Cl_mole_flux_phy'},
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {length-dx/2.,0.0,dx/2.},
--                                       vec = {0.0,height,0.0},
--                                       segments = nHeight+2}
--            },
--    output={format='ascii'},
--    reduction={'average','average','average','average','average','average','average','average'},
--    time_control={ min=0, max = tmax_p, interval = dt}
--  }
--  ,
--  {
--    label = 'aem_numDens',
--    variable = {'H2O_mole_density_phy','Na_mole_density_phy','Cl_mole_density_phy',
--                'mole_density_phy',
--                'H2O_mole_flux_phy','Na_mole_flux_phy','Cl_mole_flux_phy'},
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {0.0,dx/2,dx/2.0},
--                                       vec = {length,0.0,0.0},
--                                       segments = nLength+2}
--            },
--    output={format='ascii'},
--    reduction={'average','average','average','average','average','average','average'},
--    time_control={ min=0, max = tmax_p, interval = dt}
--  }
--  ,
--  {
--    label = 'cem_numDens',
--    variable = {'H2O_mole_density_phy','Na_mole_density_phy','Cl_mole_density_phy',
--                'mole_density_phy',
--                'H2O_mole_flux_phy','Na_mole_flux_phy','Cl_mole_flux_phy'},
--    folder=tracking_fol,            
--    shape = {kind='canoND', object = { origin = {0.0,height-dx/2.,dx/2.0},
--                                       vec = {length,0.0,0.0},
--                                       segments = nLength+2}
--            },
--    output={format='ascii'},
--    reduction={'average','average','average','average','average','average','average'},
--    time_control={ min=0, max = tmax_p, interval = dt}
--  }
--  ,
--  {
--    label = 'tot_numDens',
--    variable = {'H2O_mole_density_phy','Na_mole_density_phy','Cl_mole_density_phy',
--                'mole_density_phy',
--                },
--    folder=tracking_fol,            
--    shape = {kind='all'},
--    output={format='ascii'},
--    reduction={'average','average','average','average'},
--    time_control={ min=0, max = tmax_p, interval = dt}
--  }

} -- tracking
