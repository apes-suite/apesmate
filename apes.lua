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
require('treelm/config')

simulation_name = 'sample'

sim_control = {
  time_control = { 
    max = 1.0
  }
}          

-- Logic to distribute all domains on all process equally
-- default is false
share_domain = true

-- Logical to define if domain partition is done via fraction or by number of process
-- if this is true, in domain object it looks for nProc_frac 
-- if this is false, in domain object it looks for nProc
nproc_is_frac = true -- true is default

-- Provide name of the solver, configuration file for that solver, 
-- identification label for that domain and 
-- nProc in fraction satisfying that nProc_frac from all domain sum to unity.
domain_object = {
  {
    label = 'domain_1',
    solver = 'musubi',
    filename = 'plugins/APES_musubi/musubi.lua',
    nProc_frac = 2.0/5.0
    -- nProc = 2 -- if  nproc_is_frac=false you need to specify the 
                 --number of process - NOT the fraction!
  }
-- ,{
--    label = 'domain_2',
--    solver = 'musubi',
--    filename = 'plugins/APES_musubi/musubi.lua',
--    nProc_frac = 3.0/5.0
--  }
-- ,{
--    label = 'domain_3',
--    solver = 'musubi',
--    filename = 'plugins/APES_musubi/musubi.lua',
--    nProc_frac = 2.0/5.0
--  }
-- ,{
--    label = 'domain_4',
--    solver = 'musubi',
--    filename = 'plugins/APES_musubi/musubi.lua',
--    nProc_frac = 1.0/5.0
--  }
}  

