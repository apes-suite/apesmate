require 'common'
require "musubi_PB"
simulation_name = 'EOF_Pot'
restart = {
  read = 'restart_PB/PB_lastHeader.lua'
}
tracking = {
  {
    label = 'line',
    folder = 'tracking_PB/',
    NOvariable = {'potential_phy','electric_field_phy','analy_pot', 'cpl_charge_dens'},
    variable = {'potential_phy','electric_field_phy','analy_pot',
                'analy_charge_dens','analy_electric_field'},
    shape = {
      kind = 'all',
      object = {
        origin ={dx/2.0,-dx,zpos},
        vec = {0.0,height+2*dx,0.0},
        segments = nHeight+2
      }
    },
    NOtime_control = {min = {iter=tmax}, max = {iter=tmax}, interval = {iter=tmax}},
    output={format = 'asciiSpatial'}
  },
}
