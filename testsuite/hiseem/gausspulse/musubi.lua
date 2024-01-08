require "common_aps"
require "seeder_mus"

-- time step size 
dt = (resi_ref/resi_latt)*dx*dx
--u_mean_L = 0.05
--dt = u_mean_L/u_mean_phy*dx
--resi_latt = resi_ref*dx*dx/dt
--omega
omega_diff = 1.0
--omega_kine = 1.0
--nu_L = (1.0/(3.0*omega_kine))
--dt = nu_L*dx^2./nu_phy
nu_L = nu_phy * dt / dx^2
omega_kine = 1.0/(3.0*nu_L)
u_mean_L = u_mean_phy*dt/dx
Re_l = u_mean_L*nHeight/nu_L
--print('dt =', dt)
--print('u_mean_L ',u_mean_L)
--print('omega_kine ', omega_kine)
resi_latt = resi_ref*dx*dx/dt
--print('resi_latt ', resi_latt)


tracking_fol = 'tracking_mus_n'..nHeight..'/'
scheme_kind = 'bgk_forcing'
scheme_kind = 'mrt_withthermodynfac'
scheme_kind = 'bgk_withthermodynfac'
scheme_kind = 'bgk'
scheme_kind = 'mrt'
-- Musubi configuration file. 
-- This is a LUA script.

simulation_name = 'gauss'
mesh = 'mesh_mus/'--_n'..nHeight..'/'

NOdebug = {
  logging = {level=1, filename = 'dbg_mus', root_only = false}, 
  debugMode = true, debugFiles = true
}
logging = {level=5, 
--           filename = 'log_mus'
}

-- Time step settigs
sim_control = {
  time_control = {
    --max = tmax_p/100,
    max = tmax_p, 
    interval = tmax_p/100
    --max = {iter=10},
    --interval = {iter=1}
  }
}

-- restart
restart = {
  --read = 'restart/taylorDispersion_header_25.004E-03.lua',
  NOread = 'restart_mus/taylorDispersion_lastHeader.lua',
  write = 'restart_mus/',
  time_control = { min = tmax_p, max = tmax_p, interval = tmax_p}
}

physics = { --rho0 = rho0_p, 
            dt = dt, 
            --mass0 = 1.0,
            molWeight0 = m_min, 
            temp0 = 273.0,
            --moleDens0 = moleDens0,
            --coulomb0 = 1.0
}

scaling = 'diffusive'
-- scheme model for single fluid simulation
identify = {
    kind = 'multi-species_liquid', 
    relaxation = scheme_kind, 
-- scheme layout
    layout = 'd3q19'
}

glob_source = { electric_field = 'electric' }

mixture = { rho0 = rho0_p, moleDens0 = moleDens0,
            omega_diff = omega_diff,
            --kine_shear_viscosity = nu_phy,
            --bulk_viscosity = 1e-5,
            omega_kine = omega_kine,
            omega_hom = 1.0,
            theta_eq = 1.0,
            temp = 293.15,
	    prop_file = 'H2O_NaCl.dat',
            electricField = { 0.0, electric_field_external, 0.0},
            --gravityField = { 1e-4,0.0,0.0},
            initial_condition = { pressure = 0.0}--TGV_kinematicPressure }
          }

-- user variables
variable = {
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
    },
    boundary_condition = {
      {
        label = 'north',
        kind = 'wall'
      },
      {
        label = 'south',
        kind = 'wall'
      },
      {
        label = 'west',
        kind = 'wall'
      },
      {
        label = 'east',
        kind = 'wall'
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
      velocityX = IC_velocity,
      velocityY = 0.0,
      velocityZ = 0.0
    },
    boundary_condition = {
      {
        label = 'north',
        kind = 'wall'
      },
      {
        label = 'south',
        kind = 'wall'
      },
      {
        label = 'west',
        kind = 'wall'
      },
      {
        label = 'east',
        kind = 'wall'
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
      velocityX = IC_velocity,
      velocityY = 0.0,
      velocityZ = 0.0
    },
    boundary_condition = {
      {
        label = 'north',
        kind = 'wall'
      },
      {
        label = 'south',
        kind = 'wall'
      },
      {
        label = 'west',
        kind = 'wall'
      },
      {
        label = 'east',
        kind = 'wall'
      },
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
    output={format='vtk', iter_filename = false},
    --time_control={ min=0, max = tmax_p, interval = tmax_p/50}
    time_control={ min=0, max = tmax_p, interval = tmax_p/20}
    --time_control={ min=0, max = tmax_p, interval = {iter=1}}
  }
}
