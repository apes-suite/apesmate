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

-- Global parameters
cube_length = 10.

-- Include general treelm settings
--require('treelm/config')
logging = {level=10,filename ='log_apes'}

simulation_name = 'Euler_Euler'
sim_control = {
             time_control = {
                  min = 0,
                  max = {iter=2000},
                  interval = {iter = 10}, -- final simulation time
                }
}

--nproc_is_frac = false

domain_object = {
  {
    label = 'left_domain',
    solver = 'ateles',
    filename = 'ateles_left.lua',
    nProc_frac = 0.5
    --nProc = 1
  },
  {
    label = 'right_domain',
    solver = 'ateles',
    filename = 'ateles_right.lua',
    nProc_frac = 0.5
   -- nProc = 1
  }
}  
