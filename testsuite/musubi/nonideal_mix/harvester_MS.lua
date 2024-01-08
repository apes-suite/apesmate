require 'common'
require 'musubi_MS'
simulation_name = 'EOF_MS'
restart = {
  read = 'restart_MS/EOF_lastHeader.lua'
}
tracking = {
  {
    label = 'line',
    folder = 'tracking_MS/',
    variable = {
                'Na_mole_density_phy', 'Cl_mole_density_phy',
                'charge_density_phy',  'current_density_phy',
                'velocity_phy','velocity'
    },            
    shape = {
      kind = 'all',
    },
    NOtime_control = {min = {iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}},
    output={format = 'asciiSpatial'}
  },
}
