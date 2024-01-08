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
require "common"
simulation_name = 'channel2D'

debug = {logging = {level=1, filename='aps_dbg', root_only=false}}
logging = { level=5, filename = 'log_apes'}

sim_control = {
  time_control = { 
    --max = { sim = tmax_p,
    --        iter = 1},
    max = tmax,
    interval = {iter=100}        
  }
}          

nproc_is_frac = true 

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_left',
    solver = 'musubi',
    filename = 'musubi_left.lua',
    nProc_frac = 1 
  },
  {
    label = 'dom_right',
    solver = 'musubi',
    filename = 'musubi_right.lua',
    nProc_frac = 1
  }
}  
