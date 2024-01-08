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
require "common_aps"
simulation_name = 'gauss'

NOdebug = {logging = {level=1, filename='dbg_aps', root_only=false}}
logging = { level=5, 
            filename = 'log_apes'
}

sim_control = {
  time_control = { 
    --max = tmax_p,
    --interval = {iter=100}
    max = {iter=10,clock = 60*60},
    interval = {iter=1}
  }
}          

nproc_is_frac = true 

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'dom_musubi',
    solver = 'musubi',
    filename = 'musubi.lua',
    nProc_frac = 1 
  },
  {
    label = 'dom_ateles',
    solver = 'ateles',
    filename = 'ateles.lua',
    nProc_frac = 1
  }
}  
