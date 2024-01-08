require "ateles"

simulation_name = 'taylorDispersion'

-- define the input
restart = {
  read = 'restart_atl/maxwell_source_lastHeader.lua'
}

-- define the output
tracking = {
    label = 'vtk',
    folder='tracking_atl/',
    NOvariable = {'var_charge_density'},
    variable = {'displacement_field','permittivity','var_charge_density',
                'var_current_density'},
    shape = {kind='all'},
    output={format='vtk'},
}
