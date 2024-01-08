----------------------- PLEASE READ THIS ---------------------------!!!

-- This input file is set up to run for regression check
-- Please make sure you DO NOT MODIFY AND PUSH it to the repository
                                                                          
--------------------------------------------------------------------!!!
-- Musubi configuration file. 
require "common"
coupled = os.getenv('coupled')
tracking_fol = './tracking_MS/'
scheme_kind = 'mrt'

bc_nacl_north = 'wall'
bc_nacl_south = 'wall'

bc_h2o = 'wall'

-- simulation paramters
io_buffer_size = 1
printRuntimeInfo = true
timing_file = 'timing_MS.res'

---- communication pattern
--isend_irecv_overlap gathered_type isend_irecv typed_isend_irecv
commpattern = 'isend_irecv'
control_routine = 'fast'
-- Simulation name
simulation_name = 'EOF'
mesh = 'mesh/'

scaling = 'diffusive'
logging = {level=10, filename = 'log_MS'}

NOdebug = {logging = {level=1, filename = 'dbg_bgk.out'},
         debugMode = true, debugFiles = true, verbose =  true, verboseLevel = 100}

tmax = tmax 
interval = tmax/100
-- Time step settings
sim_control = {
  --time_control = {
  --  max = {iter=1}, 
  --  interval = {iter=1},
  --  check_iter = 10
  --}
  time_control = {
    max = {iter=tmax}, 
    interval = {iter=interval},
    check_iter = 1
  }
}

-- restart
restart = {
  NOread = 'restart_MS/EOF_lastHeader.lua',
  write = 'restart_MS/',
  NOtime_control = { min = tmax_p, max = tmax_p, interval = tmax_p}
}

physics = { rho0 = rho0_p, 
            dt = dt, 
            --molWeight0 = m_min, 
            temp0 = temp,
            moleDens0 = moleDens0,
            --coulomb0 = 1.0
}

-- scheme model for single fluid simulation
identify = {
    kind = 'multi-species_liquid', 
    relaxation = scheme_kind, 
-- scheme layout
    layout = 'd2q9'
}

mixture = { rho0 = rho0_p, moleDens0 = moleDens0,
            omega_diff = omega_diff,
            kine_shear_viscosity = nu_phy,
            --bulk_viscosity = 1e-7,
            --omega_kine = omega_kine,
            omega_hom = 2.0,
            theta_eq = 1.0,
            temp = temp,
	    prop_file = 'H2O_NaCl.dat',
            initial_condition = { pressure = 0.0}--TGV_kinematicPressure }
          }

-- user variables
variable = {}
if coupled=='true' then
  print('coupled: ', coupled)
  table.insert(variable,
    { name = 'cpl_electric',
      ncomponents = 3,
      vartype = 'st_fun',
      st_fun = { 
        predefined = 'apesmate',
        domain_from = 'dom_Poisson',
        input_varname = {'electric_field_phy'}
      }
    }
  )
else  
  table.insert(variable,
    { name = 'cpl_electric',
      ncomponents = 3,
      vartype = 'st_fun',
      st_fun = analy_electric_field
    }
  )
end

table.insert(variable,
  { 
    name = 'external_electric',
    ncomponents = 3,
    vartype = 'st_fun',
    st_fun = {1e4,0.0,0.0}
  }
)
table.insert(variable,
  {
    name = 'tot_electric',
    ncomponents = 3,
    vartype = 'operation',
    operation = {
      kind = 'addition',
      input_varname = {'external_electric','cpl_electric'}
    }
  }
)

glob_source = {electric_field_1order_diff = 'cpl_electric'}
-- field which defines fluid or specie
-- Single fluid simulation
field = {{
  --source = {electric_field = 'cpl_electric'},
  label = 'H2O'
-- species properties
   ,species = { molweight = mH2O, 
                diff_coeff = { diff_diag, diff_H2O_Na, diff_H2O_Cl },
                charge_nr = charge_nr_H2O}
-- Initial condition
   ,initial_condition = { 
      mole_fraction = IC_H2O,
      velocityX = 0.0,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     { label = 'north', 
       kind = bc_h2o,
       mole_fraction = BC_H2O,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0}
     },
     { label = 'south', kind = bc_h2o,
       mole_fraction = BC_H2O,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0}
     },
    }
  }
 ,{
    label = 'Na'
   ,species = { molweight = mNa, 
                diff_coeff = { diff_H2O_Na, diff_diag, diff_Na_Cl },
                charge_nr = charge_nr_Na}
   ,initial_condition = {
      mole_fraction = IC_Na,
      velocityX = 0.0,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     { label = 'north', 
       kind = bc_nacl_north,
       mole_fraction = BC_Na_north,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0},
       mole_density = conc_Na*math.exp(-(charge_nr_Na*faraday/(gasConst*temp))*pot_north),
       transference_number = 0.971 
     },
     { label = 'south', 
       kind = bc_nacl_south,
       mole_fraction = BC_Na_south,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0},
       mole_density = conc_Na*math.exp(-(charge_nr_Na*faraday/(gasConst*temp))*pot_south),
       transference_number = (1.0-0.998)
     },
    }
  }
 ,{
    label = 'Cl'
   ,species = { molweight = mCl, 
                diff_coeff = { diff_H2O_Cl, diff_Na_Cl, diff_diag },
                charge_nr = charge_nr_Cl}
   ,initial_condition = {
      mole_fraction = IC_Cl,
      velocityX = 0.0,
      velocityY = 0.0,
      velocityZ = 0.0
    }
   ,boundary_condition = {
     { label = 'north', 
       kind = bc_nacl_north,
       mole_fraction = BC_Cl_north,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0},
       mole_density = conc_Cl*math.exp(-(charge_nr_Cl*faraday/(gasConst*temp))*pot_north),
       transference_number = (1.0-0.971) 
     },
     { label = 'south', 
       kind = bc_nacl_south,
       mole_fraction = BC_Cl_south,
       velocity = {0.0,0.0,0.0},
       mole_flux = {0.0,0.0,0.0},
       mole_density = conc_Cl*math.exp(-(charge_nr_Cl*faraday/(gasConst*temp))*pot_south),
       transference_number = 0.998 },
    }
  }
}
NOtracking = {
  {
    label = 'line_height',
    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy','velocity_phy'},
    folder=tracking_fol,            
    shape = {kind='canoND', object = { origin = {length/2.0,-offset,dx/2.},
                                       vec = {0.0,height,0.0},
                                       segments = nHeight+2}
            },
    output={format='asciiSpatial'},
    time_control={ min={iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}}
    --time_control={ min=0, max = {iter=tmax}, interval = {iter=100}}
  },
  {
    label = 'probe_hdiv4',
    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy','velocity_phy'},
    folder=tracking_fol,            
    shape = {kind='canoND', object = { origin = {length/2.0,3*height/4-dx/2.0-offset,dx/2.},
            },
    },        
    output={format='ascii'},
    time_control={ min=0, max = {iter=tmax}, interval = {iter=10}}
  },
  {
    label = 'probe_north',
    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy','velocity_phy'},
    folder=tracking_fol,            
    shape = {kind='canoND', object = { origin = {length/2.0,height-dx/2.0-offset,dx/2.},
            },
    },        
    output={format='ascii'},
    time_control={ min=0, max = {iter=tmax}, interval = {iter=10}}
  },
  {
    label = 'probe_south',
    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy','velocity_phy'},
    folder=tracking_fol,            
    shape = {kind='canoND', object = { origin = {length/2.0,dx/2.0-offset,dx/2.},
            },
    },        
    output={format='ascii'},
    time_control={ min=0, max = {iter=tmax}, interval = {iter=10}}
  },

  {
    label = 'probe_center',
    variable = {'H2O_mole_density_phy', 'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy','velocity_phy'},
    folder=tracking_fol,            
    shape = {kind='canoND', object = { origin = {length/2.0,height/2.0-offset,dx/2.},
            },
    },        
    output={format='ascii'},
    time_control={ min=0, max = {iter=tmax}, interval = {iter=10}}
  },

} -- tracking
