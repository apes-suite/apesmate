-- This is the standard apes configuration, that should document the possible
-- and required configuration options.
--
-- WARNING!!!
-- LEAVE THIS FILE UNCHANGED IN THE REPOSITORY
-- unless you change configurable options, in this case you should update this
-- script accordingly.
--
-- This script should always serve as an example which runs "out of the box".
-- 
-- Thank you!
-- ------------------------------------------------------------------------- --
simulation_name = 'gauss_pulse'
tmax = 0.25
--debug = {logging = {level=1, filename='aps_dbg', root_only=false}}
--logging = { level=5}
logging = { level=5}

sim_control = {
  time_control = { 
    max = tmax,
    interval = {iter=1}        
  }
}          

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_euler',
    solver = 'ateles',
    filename = 'ateles_euler.lua',
    nProc_frac = 0.5
  },
  {
    label = 'dom_lineuler',
    solver = 'ateles',
    filename = 'ateles_lineuler.lua',
    nProc_frac = 0.5
  }
}  
