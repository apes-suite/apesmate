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

debug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=5, filename = 'log_apes'}

sim_control = {
  time_control = { 
    --max = { sim = tmax_p,
    --        iter = 1},
    max =1,
    interval = {iter=1}        
  }
}          

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_left',
    solver = 'ateles',
    filename = 'ateles_left.lua',
    nProc_frac = 1.0
  },
  {
    label = 'dom_right',
    solver = 'ateles',
    filename = 'ateles_right.lua',
    nProc_frac = 1.0
  }
}  
