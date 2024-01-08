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

require 'common'
require 'musubi'

simulation_name = 'spacerLab'

sim_control = {
  time_control = { 
    --max = { sim = tmax_p,
    --        iter = 1},
    max = 5*dt,
    interval = {iter=1}        
  }
}          

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'domain_1',
    solver = 'musubi',
    filename = 'musubi.lua',
    nProc_frac = 1.0
  },
  {
    label = 'domain_2',
    solver = 'musubi',
    filename = 'musubi_2dt.lua',
    nProc_frac = 1.0
  }
}  
