simulation_name = 'taylorDispersion'

-- define the input
restart = {
  read = 'restart/taylorDispersion_lastHeader.lua'
}

-- define the output
tracking = {
    label = 'vtk',
    variable = {
                'vel_mag_phy', 'H2O_mole_density_phy', 
                'Na_mole_density_phy', 'Cl_mole_density_phy',
                'velocity_phy', 'H2O_mole_fraction', 
                'Na_mole_fraction', 'Cl_mole_fraction',
                'charge_density_phy', 'current_density_phy'
                },
    folder='tracking/',
    shape = {kind='all'},
    output={format='vtk'},
}
